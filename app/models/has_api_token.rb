module HasApiToken
  extend ActiveSupport::Concern

  def find_by_id_and_api_key(id, api_key)
    self.class.where(id: id, api_key: api_key).first
  end

  private
  def generate_api_key
    self.api_key ||= Digest::SHA1.hexdigest(Time.now.to_s + attributes.inspect)
  end
end