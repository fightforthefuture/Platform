require 'uri'
require 'net/http'
require 'json'

module SendgridHelper
  # Get stats associated with an email from SendGrid
  #
  # Returns a hash of numbers like
  #
  #  {"delivered"=>0, "unsubscribes"=>0, "name"=>"email_1000",
  #  "invalid_email"=>0, "bounces"=>0, "repeat_unsubscribes"=>0,
  #  "unique_clicks"=>0, "spam_drop"=>0, "repeat_bounces"=>0,
  #  "repeat_spamreports"=>0, "blocked"=>0, "requests"=>0,
  #  "spamreports"=>0, "clicks"=>0, "opens"=>0, "unique_opens"=>0}
  def sendgrid_email_stats(email_id)

   uri = "http://sendgrid.com/api/stats.get.json?aggregate=1&category=#{email_id}&api_user=#{AppConstants.sendgrid_api_user}&api_key=#{AppConstants.sendgrid_api_password}"

    # SendGrid returns a list, so unwrap the single element in that list.
    JSON.parse(Net::HTTP.get(URI.parse(uri)))[0]
  end

end
