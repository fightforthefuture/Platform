class Api::MembersController < Api::BaseController
  MEMBER_FIELDS = [:id, :first_name, :last_name, :email, :country_iso, :postcode, :home_number, :mobile_number, :street_address, :suburb]
  respond_to :json

  # before_filter :verify_request, :only => :create_from_salsa
  after_filter :set_access_control_headers, :only => [:create_from_salsa, :unsubscribe]

  def show
    @member = movement.members.find_by_email(params[:email]) unless params[:email].blank?

    if @member
      render :json => @member.as_json(:only => MEMBER_FIELDS), :status => :ok
    else
      status_response = params[:email].blank? ? :bad_request : :not_found
      render :nothing => true, :status => status_response
    end
  end

  def unsubscribe
    if params[:t]
      hash = EmailTrackingHash.decode(params[:t])
      email = hash.email
      user = hash.user
    elsif params[:member][:email]
      movement = Movement.find(1)
      email = nil
      user = User.for_movement(movement).where(:email => params[:member][:email]).first
    end

    user.unsubscribe!(email)

    render json: {data: {success: true}}}
  end
  
  def create_from_salsa
    (render :json => { :errors => "Language field is required"}, :status => 422 and return) if params[:member][:language].blank?
    (render :json => { :errors => "There was a problem processing your request"}, :status => 422 and return) unless params[:guard].blank?
    
    tag = params[:tag] || 'untagged'

    movement = Movement.find(1)

    unless @page = ActionPage.find_by_name(tag)
      campaign = Campaign.find_by_name('CMS')
      
      @page = ActionPage.create(
        name: tag,
        movement_id: 1,
        type: 'ActionPage',
        action_sequence_id: campaign.action_sequences.first.id
      )

      petition = PetitionModule.create!(
        :title => "Sign, please",
        :content => 'We the undersigned...',
        :petition_statement => "This is the petition statement",
        :signatures_goal => 1,
        :thermometer_threshold => 0,
        :language => Language.find_by_iso_code(:en)
      )
      ContentModuleLink.create!(:page => @page, :content_module => petition, :position => 3, :layout_container => :main_content)
    end
    
    member_params = params[:member].merge({'language' => Language.find_by_iso_code(params[:member][:language])})
    
    member_scope = User.for_movement(movement).where(:email => params[:member][:email])
    member = member_scope.first || member_scope.build
    
    member.take_action_on!(@page, { :email => params[:member][:info] }, member_params)

    begin
      join_email = movement.join_emails.first {|join_email| join_email.language == member.language}
      SendgridMailer.delay.user_email(join_email, member)
    rescue
    end
    
    render json: {data: {success: true}}}
  end

  def create
    (render :json => { :errors => "Language field is required"}, :status => 422 and return) if params[:member][:language].blank?

    @member = movement.members.find_or_initialize_by_email(params[:member][:email])
    @member.language = Language.find_by_iso_code(params[:member][:language])
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
