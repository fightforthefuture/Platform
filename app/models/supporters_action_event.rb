module SupportersActionEvent
  # Delete any old jobs and associated tables. We arbitrarily delete
  # jobs that are over a day old (and have been completed.)
  def self.garbage_collect
    jobs = SupportersActionJob.where("complete = ? AND created_at <= ?", true, DateTime.yesterday)
    jobs.find_each do |job|
      case job.operation
      when "query"
        query = "DROP TABLE #{SupportersActionEvent::job_table(job.id)}"
        ActiveRecord::Base.connection.execute(query)
        job.delete!
      else
        job.delete!
      end
    end
  end

  def self.job_table(job_id)
    "supporters_action_#{job_id}"
  end


  class Event
    # job is a SupportersActionJob
    def initialize(movement_id, job_id)
      @movement_id = movement_id
      @job_id = job_id
    end

    def handle
      @movement = Movement.find_by_id(@movement_id)
      @job = SupportersActionJob.find_by_id(@job_id)
      # Every time we run an event, do a garbage collection pass
      # first. This should be fairly fast, as there shouldn't be many
      # old jobs to clean up.
      SupportersActionEvent::garbage_collect
    end

    def make_query(job)
      add_page_name_clause(
        add_user_clause(
          add_user_clause(
            add_user_clause(User.for_movement(@movement), 'first_name', job.first_name),
            'last_name',
            job.last_name
          ),
          'email',
          job.email_address
        ),
        job.page_name
      )
    end

    def add_user_clause(query, name, param)
      if param and not param.empty?
        query.where("#{name} LIKE ?", param)
      else
        query
      end
    end

    def add_page_name_clause(query, page_name)
      if page_name and not page_name.empty?
        query.joins(user_activity_events: :page).where(pages: { name: page_name })
      else
        query
      end
    end
  end


  class Subscribe < Event
    def initialize(movement_id, job_id, request)
      super(movement_id, job_id)
      @remote_ip = request.remote_ip
      @refer = request.referer
    end


    def handle
      super

      supporters = make_query(@job).readonly(false)
      supporters.find_each do |supporter|
        supporter.ip_address = supporter.ip_address || @remote_ip
        supporter.referer_url = supporter.referer_url || @referer
        supporter.join_through_external_action!
      end
      @job.complete!
    end
  end


  class Unsubscribe < Event
    def handle
      super

      supporters = make_query(@job).readonly(false)
      supporters.find_each do |supporter|
        supporter.unsubscribe!
      end
      @job.complete!
    end
  end


  class Delete < Event
    def initialize(movement_id, job_id, page_name)
      super(movement_id, job_id)
      @page_name = page_name
    end

    def handle
      super

      supporters = make_query(@job).readonly(false)
      supporters.find_each do |supporter|
        query = <<-eos
              SELECT COUNT(uae.id) AS count FROM user_activity_events AS uae, pages
              WHERE uae.page_id = pages.id
              AND pages.name <> '#{@page_name}'
              AND uae.user_id = #{supporter.id}
            eos
        results = ActiveRecord::Base.connection.execute(query)
        can_delete = results.first[0] == 0
        if can_delete
          # Delete this user and tags associated with them
          query = <<-eos
                DELETE users, uae
                FROM users, user_activity_events AS uae
                WHERE users.id = #{supporter.id}
                AND uae.user_id = users.id
              eos
          ActiveRecord::Base.connection.execute(query)
        else
          # Delete just the events associated with this tag
          query = <<-eos
                DELETE uae
                FROM user_activity_events AS uae, pages
                WHERE uae.user_id = #{supporter.id}
                AND uae.page_id = pages.id
                AND pages.name = '#{@page_name}'
              eos
          ActiveRecord::Base.connection.execute(query)
        end
      end
      @job.complete!
    end
  end


  class Query < Event
    def handle
      super

      supporters = make_query(@job)
      query = "CREATE TABLE #{SupportersActionEvent::job_table(@job.id)} AS #{supporters.to_sql}"
      ActiveRecord::Base.connection.execute(query)
      @job.complete!
    end
  end
end
