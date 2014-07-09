module Admin
  class SupportersController < AdminController
    layout 'movements'
    def index
      @supporters = User.limit(10).for_movement(@movement)
    end

    def search
      @first_name = params[:first_name]
      @last_name = params[:last_name]
      @email_address = params[:email]
      @supporters =
        add_param_for_search(
          add_param_for_search(
            add_param_for_search(User.for_movement(@movement), 'first_name', @first_name),
            'last_name',
            @last_name
          ),
          'email',
          @email_address
        )
    end

    def add_param_for_search(query, name, param)
      if param and not param.empty?
        query.where("#{name} LIKE ?", param)
      else
        query
      end
    end
  end
end
