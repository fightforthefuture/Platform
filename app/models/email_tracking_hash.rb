class EmailTrackingHash < Struct.new(:email, :user)

  # Decode a hash into email ID and usr ID without hitting the
  # database. Returns array email_id, user_id as integers.
  def self.decode_raw(hash)
    hash ||= ""
    data_pairs = Base64.urlsafe_decode64(hash).split ","
    attrs = data_pairs.inject({}) do |hash, pair|
      key, value = pair.split "="
      hash.merge key.to_sym => value
    end

    email_id = attrs[:emailid]
    user_id = attrs[:userid]

    [email_id.to_i, user_id.to_i]
  end

  def self.decode(hash)
    email_id, user_id = self.decode_raw(hash)

    email = Email.where(:id => email_id).first
    user  = User.where(:id => user_id).first

    self.new email, user
  rescue ArgumentError # "invalid base64"
    self.new nil, nil
  end

  def valid?
    email.present? && email.is_a?(Email) && user.present? && user.is_a?(User)
  end

  def encode
    if email.is_a?(AutofireEmail) || email.is_a?(JoinEmail)
      ""
    else
      raise "Cannot encode invalid tracking hash; requires an email (was: #{self.email}) and a user (was: #{self.user})" unless valid?
      Base64.urlsafe_encode64("userid=#{self.user.id},emailid=#{self.email.id}")
    end
  end

  def email_id
    self.email.try(:id)
  end

  def user_id
    self.user.try(:id)
  end
end
