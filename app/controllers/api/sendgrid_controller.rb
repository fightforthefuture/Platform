require 'json'

class Api::SendgridController < Api::BaseController

  http_basic_authenticate_with name: AppConstants.sendgrid_user, password: AppConstants.sendgrid_password

  def event_handler
    events = JSON.parse(request.body.read)
    events.each do |evt|
      handle_event(@movement.id, evt)
    end

    head :ok
  end

  def handle_event(movement_id, event)
    evt = SendgridEvents::create(movement_id, event)
    evt.delay.handle
  end


  def unsubscribe_handler
    address = params[:to]
    from_address = params[:from]

    Rails.logger.info "Processing unsubscribe to: #{address}, from: #{from_address}."

    begin
      if address and from_address and ListUnsubscribe.valid_unsubscribe_email_address?(address, from_address, @movement)
        member = User.find_by_movement_id_and_email(@movement.id, from_address)
        if member
          member.unsubscribe!
        end
      end
    ensure
      head :ok
    end
  end

end
