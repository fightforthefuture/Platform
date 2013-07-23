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
    if params[:user].has_key? :tag
      page_name = params[:user].delete(:tag).first
    else
      page_name = nil
    end
    @user = create_from_salsa(params)
    if @user.valid?
      @user.save!
      associate_user_with_page(@user, page_name)
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
    
    user_hash = {}
    params[:user].each_pair do |k,v|
      user_hash.merge!({k.downcase.to_sym => v}) 
    end
    
    user_hash[:email] = user_hash[:email].first

    @user = User.find_by_email(user_hash[:email].first) || User.new(user_hash)
    return @user
  end
  
  def associate_user_with_page(user, name=nil)
    if !name.nil?
      page = Movement.first.pages.find_or_create_by_name(name)
      user_activity_event = UserActivityEvent.subscribed!(user, nil, page)
    else
      user_activity_event = UserActivityEvent.create(:user => user)
    end
    user_activity_event.campaign = Campaign.first
    user_activity_event.save!
  end
end
