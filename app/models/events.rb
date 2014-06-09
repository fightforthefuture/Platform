require 'newrelic_rpm'

module Events

  class Event
    def handle
      NewRelic::Agent.increment_metric("Custom/Event/#{@name}", 1)
      # Do whatever this event needs to do
    end

    def to_s
      @name ||= "Event"
      "#{@name}(#{@movement_id}, #{@email_address}, #{@email_id})"
    end

    def initialize(movement_id, email_address, email_id)
      @movement_id = movement_id
      @email_address = email_address
      @email_id = email_id
    end

    # Returns truthy on success, false otherwise
    #
    # Note the success value only indicates that the handler could run
    # without error. If you create a handler with a bogus email
    # address, for instance, it will run succesfully but won't do
    # anything.
    def handle
      NewRelic::Agent.increment_metric("Custom/Event/#{@name}", 1)
      # Do whatever this event needs to do
    end

    def to_s
      @name ||= "Event"
      "#{@name}(#{@movement_id}, #{@email_address}, #{@email_id})"
    end

    # Returns the User affected by this event
    def user
      User.find_by_movement_id_and_email(@movement_id, @email_address)
    end

    # Returns the Email that caused this event, nil if there is no email
    def email
      Email.find_by_id(@email_id)
    end
  end

  class Processed < Event
    # Do nothing
    @name = "Processed"
  end

  class Dropped < Event
    # This event is often raised when an email address is invalid but
    # could also be raised if there is an error how SendGrid is
    # called. Thus it isn't safe to unsubscribe a user generating this
    # event.
    #
    # See: http://sendgrid.com/docs/API_Reference/Webhooks/event.html
    #
    # TODO: Remove the email_send event associated with this email
    @name = "Dropped"
  end

  class Delivered < Event
    # We already record this when the email is sent to SendGrid so
    # do nothing.
    @name = "Delivered"
  end

  class Deferred < Event
    # We don't have a representation for this event so do nothing.
    @name = "Deferred"
  end

  class Bounce < Event
    @name = "Bounce"
    def handle
      super
      # Could not deliver, so unsubscribe this user.
      member = self.user
      email = self.email
      if member
        member.unsubscribe!(email)
      else
        true
      end
    end
  end

  class Open < Event
    @name = "Open"
    def handle
      super
      # Register an email_viewed event
      member = self.user
      email = self.email
      if member and email
        UserActivityEvent.email_viewed!(member, email)
      else
        true
      end
    end
  end

  class Click < Event
    @name = "Click"
    def handle
      super
      # Register an email_clicked event if we don't have one already
      member = self.user
      email = self.email
      if member and email
        UserActivityEvent.email_clicked!(member, email)
      else
        true
      end
    end
  end

  class SpamReport < Event
    @name = "SpamReport"
    def handle
      super
      member = self.user
      email = self.email
      if member and email
        member.unsubscribe!(email)
        UserActivityEvent.email_spammed!(member, email)
      else
        true
      end
    end
  end

  class Unsubscribe < Event
    @name = "Unsubscribe"
    def handle
      super
      member = self.user
      email  = self.email
      if member
        member.unsubscribe!(email)
      else
        true
      end
    end
  end


  @@the_handlers = {
    processed: Processed,
    dropped: Dropped,
    bounce: Bounce,
    delivered: Delivered,
    deferred: Deferred,
    bounce: Bounce,
    open: Open,
    click: Click,
    spamreport: SpamReport,
    unsubscribe: Unsubscribe
  }

  # Event that does nothing
  @@the_noop = Event.new(0, 'dummy', 0)

  def self.noop
    @@the_noop
  end

  # Create an Event object from SendGrid JSON
  def self.create_from_sendgrid(movement_id, evt)
    event = evt["event"]
    email_address = evt["email"]
    email_id = evt["email_id"]

    if event and email_address and email_id
      handler = @@the_handlers[event.to_sym]
      if handler
        handler.new(movement_id, email_address, email_id)
      else
        NewRelic::Agent.increment_metric('Custom/Event/NoHandler', 1)
        Rails.logger.warn "Could not find a handler to process SendGrid event #{evt}"
        @@the_noop
      end
    else
      NewRelic::Agent.increment_metric('Custom/Event/BadData', 1)
      Rails.logger.warn "Could not create a handler to process SendGrid event from #{evt}"
      @@the_noop
    end
  end

end
