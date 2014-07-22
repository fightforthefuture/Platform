module Admin
  class SupportersController < AdminController
    layout 'movements'
    def index
      query = "SELECT id, first_name, last_name, email, is_member FROM users LIMIT 10"
      @supporters = ActiveRecord::Base.connection.execute(query)
    end

    def view
      job_id = params[:job_id]

      # This allows us to populate the input fields
      job = SupportersActionJob.find_by_id(job_id)
      @first_name = job.first_name
      @last_name = job.last_name
      @email_address = job.email_address
      @page_name = job.page_name

      # We use raw SQL for performance reasons. Creating large numbers
      # of ActiveRecord objects has a high and unnecessary overhead.
      query = "SELECT id, first_name, last_name, email, is_member FROM supporters_action_#{job_id}"
      @supporters = ActiveRecord::Base.connection.execute(query)
    end

    def action
      read_search_params

      job = nil
      case @operation
      when 'unsubscribe'
        job = make_job('unsubscribe')
        SupportersActionEvent::Unsubscribe.new(@movement.id, job.id).delay.handle
      when 'subscribe'
        job = make_job('subscribe')
        SupportersActionEvent::Subscribe.new(@movement.id, job.id, request).delay.handle
      when 'delete'
        if not @page_name or @page_name.empty?
          render status: :bad_request, json: {data: {success: false, reason: "Cannot delete page without specifying a page name"}} and return
        else
          job = make_job('delete')
          SupportersActionEvent::Delete.new(@movement.id, job.id, @page_name)
        end
      when 'query'
        job = make_job('query')
        SupportersActionEvent::Query.new(@movement.id, job.id).delay.handle
      else
      end

      if job
        render json: {data: {success: true, job_id: "#{job.id}"}} and return
      else
        render status: :bad_request, json: {data: {success: false, reason: "Action #{@action} not understood"}} and return
      end
    end


    def poll
      job_id = params[:job_id]
      if job_id and not job_id.empty?
        job = SupportersActionJob.find_by_id(job_id.to_i)

        if not job
          render status: :bad_request, json: {data: {success: false, reason: "Job ID #{job_id} didn't correspond to an existing job"}}
        elsif job.complete
          render json: {data: {success: true, complete: true}}
        else
          render json: {data: {success: true, complete: false}}
        end
      end
    end


    # ----------------------------------------------------------

    private

    def make_job(operation)
      SupportersActionJob.create(operation: operation, first_name: @first_name, last_name: @last_name, email_address: @email_address, page_name: @page_name)
    end

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
