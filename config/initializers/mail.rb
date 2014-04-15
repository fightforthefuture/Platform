class Mail::Message
  def with_settings(settings)
    delivery_method.settings.merge!(settings)
    return self
  end
end

ActionMailer::Base.smtp_settings = {
  :address        => ENV["SENDGRID_HOST"] || "smtp.sendgrid.com",
  :domain         => "platform.yourname.com",
  :port           => 2525,
  :user_name      => ENV["SENDGRID_USERNAME"],
  :password       => ENV["SENDGRID_PASSWORD"],
  :authentication => :plain,
  :enable_starttls_auto => ENV["SENDGRID_TLS"] == 'true'
}
