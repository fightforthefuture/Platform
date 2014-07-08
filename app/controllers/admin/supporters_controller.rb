module Admin
  class SupportersController < AdminController
    layout 'movements'
    def index
      @supporters = User.limit(10).for_movement(@movement)
    end

    def search
      @first_name = param_for_like_search(:first_name)
      @last_name = param_for_like_search(:last_name)
      @email = param_for_like_search(:email)
      @supporters = User.for_movement(@movement).where('first_name like ? AND last_name like ? AND email like ?', @first_name, @last_name, @email)
    end

    def param_for_like_search(name)
      param = params[name]
      if param and not param.empty?
        param
      else
        '%'
      end
    end
  end
end
