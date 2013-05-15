class Fftf::UsersController < Fftf::BaseController
  
  respond_to :json
  
  #TODO write real docs
  # Create accepts all user attributes
  # in addition to movement_id
  #
  # Requires user_id and token
  # params for authentication
  #
  def create
    @user = User.create(params[:user]) unless User.find(params[:user][:id])
    if @user.valid?
      if params[:user][:movement_id].present?
        @movement = Movement.find(params[:user][:movement_id])
        @movement.members << @user
        MailSender.new.send_join_email(@member, movement)
      end
      response = @user.as_json.merge({success: true, user_id: @user.id})
    else
      response = {success: false, errors: @user.errors.messages}
    end
    render json: response, status: response[:success] ? 201 : 422
  end
end
