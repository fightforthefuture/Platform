class Api::MembersController < Api::BaseController

  # before_filter :verify_request, :only => :create_from_salsa
  after_filter :set_access_control_headers, :only => [:create_from_salsa, :unsubscribe]

  def show
    @member = movement.members.find_by_email(params[:email]) unless
                                                           params[:email].blank?

    if @member
      render :json => @member.as_json(:only => MEMBER_FIELDS), :status => :ok
    else
      status_response = params[:email].blank? ? :bad_request : :not_found
      render :nothing => true, :status => status_response
    end
  end

  def signature_count
    tag = params[:tag]
    page = Page.where(name: tag).first
    count = UserActivityEvent.where(page_id: page.id, user_response_type: 'PetitionSignature').count
    render json: {data: {count: count}}
  end

  def unsubscribe
    if params[:t]
      email_id, user_id = EmailTrackingHash.decode_raw(params[:t])
      user = User.find_by_id(user_id)
      if user
        email = user.email
      end
    elsif params[:member] && params[:member][:email]
      email_id = nil
      email = params[:member][:email]
    end

    if email
      Events::Unsubscribe.new(1, email, email_id).delay.handle

      if params[:redirect]
        redirect_to params[:redirect]
      else
        render json: {data: {success: true}}
      end
    else
      render status: :bad_request, json: {data: {success: false, reason: "No user found for the given email address"}}
    end
  end

  def get_signatures_from_tag
    # Fake error message, if key isn't correct.
    (render :json => { :errors => "Language field is required"}, :status => 422 and return) if params[:key] != 'QUDvUVyOerYK5TRCgoUiXiiGTuivBHDAfg7cOOPpCGSwsFmEoaq5TEi4vWcV'

    # Get page, based on tag.
    page = ActionPage.where(name: params[:tag]).first

    # Get a JSON of the signatures.
    signatures = User.joins("JOIN user_activity_events as uae ON uae.page_id = '#{page.id}' AND uae.user_id = users.id AND uae.user_response_type = 'PetitionSignature'").to_json

    # Respond.
    render :text => signatures
  end

  def create_from_salsa
    (render :json => { :errors => "Language field is required"}, :status => 422 and return) if params[:member][:language].blank?
    (render :json => { :errors => "There was a problem processing your request"}, :status => 422 and return) unless params[:guard].blank?

    email = nil
    member = nil
    movement = Movement.find(1)

    # Load user & email, from tracking hash.
    if params[:t]
      hash = EmailTrackingHash.decode(params[:t])
      email = hash.email

      if hash.user.email == params[:member][:email].downcase
        member = hash.user
      end
    end

    # Find or create user.
    if member.nil?
      member = movement.members.where(email: params[:member][:email]).
                                    first_or_initialize(member_params)
    end

    # Add website. (optional)
    if params[:website]
      member.websites << Website.new(:url => params[:website])
    end

    if request.headers['CF-Connecting-IP']
      member.ip_address = request.headers['CF-Connecting-IP']
    end

    tag = params[:tag] || 'untagged'
    @page = FightForTheFuture.find_or_create_action_page_by_tag(tag)

    member_params = params[:member].merge({'language' => Language.find_by_iso_code(params[:member][:language])})
    member.take_action_on!(@page, { :email => email }, member_params)

    if params[:redirect]
      redirect_to params[:redirect]
    else
      render json: {data: {success: true}}
    end
  end

   def create
    (render json: { errors: "Language field is required"}, status: 422 and return) if params[:member][:language].blank?

    @member = movement.members.where(email: params[:member][:email]).
                               first_or_initialize(member_params)
    @member.language = Language.where(iso_code: params[:member][:language]).first

    if @member.valid?
      @member.join_email_sent = true
      @member.subscribe_through_homepage!(tracked_email)
      MailSender.new.send_join_email(@member, movement)

      response = @member.as_json(:only => MEMBER_FIELDS).merge({
        :next_page_identifier => join_page_slug,
        :member_id => @member.id
      })
      status_response = :created
    else
      response = {
        :errors => @member.errors.messages
      }
      status_response = 422
    end

    render :json => response, :status => status_response
  end

  private

  MEMBER_FIELDS = [:id, :first_name, :last_name, :email, :country_iso,
                   :postcode, :home_number, :mobile_number, :street_address,
                   :suburb]

  MEMBER_FIELDS_FOR_CREATE = [:email, :ip_address, :referer_url, :country_iso]

  def verify_request
    ips = [
      '10.0.2.2',
      '64.99.80.30',
      '107.21.97.136',
      '76.26.200.184',
      '98.210.155.83'
    ]

    logger.info "Received request from #{request.remote_ip}"

    raise ActionController::RoutingError.new('Not Found') and return unless ips.include?(request.remote_ip)
  end

  def set_access_control_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Request-Method'] = '*'
  end

  def member_params
    params[:member].slice(*MEMBER_FIELDS_FOR_CREATE)
  end

  def join_page_slug
    movement.find_page('join').try(:slug)
  rescue
    nil
  end
end

class MailSender
  def send_join_email(member, movement)
    join_email = movement.join_emails.find {|join_email| join_email.language == member.language}
    SendgridMailer.user_email(join_email, member)
  end
  handle_asynchronously(:send_join_email) unless Rails.env.test?
end
