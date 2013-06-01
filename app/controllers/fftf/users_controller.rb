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
    @user = User.new(clean_salsa_params(params)) unless User.find(params[:user][:id])
    if @user.valid?
      MailSender.new.send_join_email(@user, movement)
      response = @user.as_json.merge({success: true, user_id: @user.id})
    else
      response = {success: false, errors: @user.errors.messages}
    end
    render json: response, status: response[:success] ? 201 : 422
  end
end
