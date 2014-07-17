module Admin
  class SupportersController < AdminController
    layout 'movements'
    def index
      @supporters = User.limit(10).for_movement(@movement)
    end

    def search
      read_search_params
      @supporters = make_query
    end

    def action
      read_search_params

      case @operation
      when 'unsubscribe'
        @supporters = make_query.readonly(false)
        @supporters.find_each do |supporter|
          supporter.unsubscribe!
        end
      when 'subscribe'
        @supporters = make_query.readonly(false)
        @supporters.find_each do |supporter|
          supporter.ip_address = supporter.ip_address || request.remote_ip
          supporter.referer_url = supporter.referer_url || request.referer
          supporter.join_through_external_action!
        end
      when 'delete'
        if not @page_name or @page_name.empty?
          render status: :bad_request, json: {data: {success: false, reason: "Cannot delete page without specifying a page name"}} and return
        else
          @supporters = make_query.readonly(false)
          @supporters.find_each do |supporter|
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
        end
    else
      render status: :bad_request, json: {data: {success: false, reason: "Action #{@action} not understood"}} and return
    end

    render :json => {data: {success: true}} and return
  end



    # ----------------------------------------------------------

    private

    def read_search_params
      @first_name = params[:first_name]
      @last_name = params[:last_name]
      @email_address = params[:email_address]
      @page_name = params[:page_name]
      @operation = get_operation
    end

    # Returns a string representing the chosen operation or nil.
    #
    # Operation is one of unsubscribe, subscribe, or delete
    def get_operation
      params[:operation]
    end

    def make_query
      add_page_name_clause(
        add_user_clause(
          add_user_clause(
            add_user_clause(User.for_movement(@movement), 'first_name', @first_name),
            'last_name',
            @last_name
          ),
          'email',
          @email_address
        ),
        @page_name
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
end
