class Fftf::UsersController < Fftf::BaseController
  
  respond_to :json
  
  #TODO write real docs
  # Create accepts all user attributes
  # in addition to movement_name
  #
  # Requires user_id and token
  # params for authentication
  #
  def create
    @user = create_from_salsa(params)
    if @user.valid?
      @user.save!
      #MailSender.new.send_join_email(@user, movement)
      response = {:user => @user.as_json, success: true, user_id: @user.id}
    else
      response = {success: false, errors: @user.errors.messages}
    end
    render json: response, status: response[:success] ? 201 : 422
  end
  
  private
  
  def create_from_salsa(params)
    @movement = Movement.first
    params[:user].merge!({:movement_id => @movement.id})
    @user = User.find_by_email(params[:user][:email]) || User.new(params[:user])
    associate_user_with_page(@user, params[:tag])
    return @user
  end
  
  def associate_user_with_page(@user, tag)
    page = Movement.first.pages.find_or_create_by_name(tag)
    UserActivityEvent.subscribed!(@user, @user.email, page)
  end
end
