class SendgridMailer < ActionMailer::Base

  def user_email(email, user, tokens = {})
    return unless user.can_subscribe?

    @body_text = pre_process_body(email.body, user, {"EMAIL_ID" => email.id, "USER" => Base64.urlsafe_encode64("userid=#{user.id},emailid=#{email.id},useremail=#{user.email}")}.merge(tokens || {}))
    @footer = email.footer

    options = {
      :to => AppConstants.no_reply_address,
      :subject => email.subject,
      :recipients => [user.email]
    }
    options.merge!({:from => email.from}) if email.respond_to?(:from)

    prepared_mail=prepare(email, false, options)
    Rails.logger.debug "EMAIL_SENDING_ISSUE: #{smtp_settings}"
    Rails.logger.debug "EMAIL_SENDING_ISSUE: #{prepared_mail.inspect}"
    Rails.logger.debug "EMAIL_SENDING_ISSUE: #{prepared_mail.delivery_method}"
    prepared_mail.deliver
    prepared_mail
  end

  # @param email (Email)
  # @param batch_number (Integer or false)
  def blast_email(email, batch_number, options)
    @body_text = { :html => email.html_body, :text => email.plain_text_body }
    # @footer = email.footer.present? ? { :html => email.footer.html_with_beacon, :text => email.footer.text } : {}
    @footer = {} # JL HACK
    options[:recipients] = clean_recipient_list(options[:recipients])

    prepare(email, batch_number, options)
  end


  def prepare(email, batch_number, options)
    headers['X-SMTPAPI'] = prepare_sendgrid_headers(email, options)
    Rails.logger.info("X-SMTPAPI is #{headers['X-SMTPAPI']}")
    headers['List-Unsubscribe' ] = prepare_unsubscribe_email_address(email, batch_number)
    subject = get_subject(email, options)

    mail(:to => AppConstants.no_reply_address, :from => email.from, :reply_to => (email.reply_to || email.from), :subject => subject) do |format|
      format.text { render 'sendgrid_mailer/text_email' }
      format.html { render 'sendgrid_mailer/html_email' }
    end.with_settings(blast_email_settings(email.movement))
  end

  def pre_process_body(body, user, tokens = {})
    raise "Error sending email: body cannot be empty" if body.blank?
    processed_body = replace_tokens(body, {
      "NAME" => user.greeting,
      "FULLNAME" => user.full_name,
      "EMAIL" => user.email,
      "POSTCODE" => user.postcode,
      "COUNTRY" => country_name(user.country_iso, user.language.iso_code.to_s),
      "PASSWORD_URL" => new_user_password_url,
      "MOVEMENT_NAME" => user.movement.name
    }.merge(tokens || {}))

    {
      :html => processed_body,
      :text => convert_html_to_plain(processed_body)
    }
  end


protected

  #TODO: #include SendGrid
  include SendgridTokenReplacement
  include InlineTokenReplacement
  include MailConfigulator
  include CountryHelper
  include EmailBodyConverter

  # Faking an email is easy, which creates a security hole allowing
  # malicious unsubscribes from Platform.  We attempt to prevent this
  # by encoding the email address and movement in the email address
  def prepare_unsubscribe_email_address(email, batch_number)
    "<mailto:#{ListUnsubscribe.encode_unsubscribe_email_address(email, batch_number, email.movement)}>"
  end


  def prepare_sendgrid_headers(email_to_send, options)
    category = email_to_send.respond_to?(:blast) ? ["push_#{email_to_send.blast.push.id}", "blast_#{email_to_send.blast.id}"] : []
    category += ["#{email_to_send.class.name.downcase}_#{email_to_send.id}", email_to_send.movement.friendly_id, Rails.env, email_to_send.language.iso_code]

    email_headers = {
      'to' => options[:recipients],
      'category' => category,
      'sub' => get_substitutions_list(email_to_send, options),
      'unique_args' => { 'email_id' => email_to_send.id }
    }

    Rails.logger.info("email_to_send is #{email_to_send}")
    Rails.logger.info("options is #{options}")
    Rails.logger.info("email_to_send.respond_to?(:blast) is #{email_to_send.respond_to?(:blast)}")
    Rails.logger.info("category is #{category}")
    Rails.logger.info("email_headers in #{email_headers}")

    raise_error_if_sizes_dont_match(options[:recipients].size, email_headers['sub'][email_headers['sub'].keys.first].size)
    email_headers.to_json
  end

  def raise_error_if_sizes_dont_match(no_recipients, no_tokens)
    if no_recipients != no_tokens
      msg = "Error sending blast: The number of recipients (#{no_recipients}) doesn't match the number of replacement tokens (#{no_tokens})."
      Rails.logger.error msg
      raise RuntimeError.new msg
    end
  end

  def get_subject(email_to_send, options)
    options[:test] ? "[TEST]#{email_to_send.subject}" : email_to_send.subject
  end

  def clean_recipient_list(recipients=[])
    if AppConstants.enable_unfiltered_blasting
      recipients
    else
      w_emails_test_domains = ENV['WHITELISTED_EMAIL_TEST_DOMAINS'].blank? ? [] : ENV['WHITELISTED_EMAIL_TEST_DOMAINS'].split(",")
      recipients.select {|email| w_emails_test_domains.any? {|domain| email.ends_with?(domain) } }
    end
  end




end
