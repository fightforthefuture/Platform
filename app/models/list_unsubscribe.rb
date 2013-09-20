require 'digest'

# This module generates and validates email addresses used in the List
# Unsubscribe header. If a fixed email address is valid for
# unsubscribes attackers can use it to maliciously unsubscribe
# others. To make this more difficult we create a hash that is
# appended to the email address. Only if this hash is valid do we
# accept unsubscribes.
module ListUnsubscribe

  # Creates a hash for securing an unsubscribe email address
  #
  # @param email_id (Integer) The id of an Email
  # @param batch_number (Integer or false) The batch number of this
  # email, or false if this email is not part of a batch.
  # @param movement (Movement) The Movement sending the email
  #
  # @return (String) A hash encoding the above information
  def self.unsubscribe_hash(email_id, batch_number, movement)
    key = "#{email_id}_#{batch_number || "nil"}_#{movement.name}_#{movement.created_at.to_s}"
    Digest::MD5.hexdigest(key)
  end

  def self.valid_regex
    base, domain = AppConstants.unsubscribe_email.split("@")
    /#{base}\+([0-9]+)_([0-9]+|nil)_([a-z0-9]+)@#{domain}+/
  end

  # Creates an email address that can be used as a List-Unsubscribe header
  # for unsubscribing from the movement.
  #
  # @param email (Email)
  # @param batch_number (Integer or false) The batch number of this
  # email, or false if this email is not part of a batch.
  # @param movement (Movement) The Movement sending the email
  #
  # @return (String) An email address
  def self.encode_unsubscribe_email_address(email, batch_number, movement)
    base, domain = AppConstants.unsubscribe_email.split("@")
    hash = unsubscribe_hash(email.id, batch_number, movement)

    "#{base}+#{email.id}_#{batch_number}_#{hash}@#{domain}>"
  end

  # Checks if an email address is a valid address to send unsubscribes to.
  #
  # @param address (String) The email address to check
  # @param from_address (String) The email address that send the unsubscribe
  # @param movement (Movement) The Movement that received the
  # unsubscribed event from SendGrid
  #
  # @return (Boolean) True if address is valid, false otherwise.
  def self.valid_unsubscribe_email_address?(address, from_address, movement)
    begin
      match = address.match(valid_regex)
      if match
        email_id = match[1]
        batch_number = match[2]
        hash = match[3]

        if batch_number == "nil"
          hash == unsubscribe_hash(email_id, batch_number, movement)
        else
          batch_number = batch_number.to_i
          user = User.where(email: from_address).first
          user_id = user.id

          push_sent_emails = PushSentEmail.where(user_id: user_id, movement_id: movement.id, email_id: email_id, batch_number: batch_number).all

          push_sent_emails.find do |pse|
            hash == unsubscribe_hash(email_id, pse.batch_number, movement)
          end
        end
      else
        false
      end
    rescue
      false
    end
  end

end
