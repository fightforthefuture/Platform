class SupportersActionJob < ActiveRecord::Base
  attr_accessible :complete, :email_address, :first_name, :last_name, :operation, :page_name, :created_at
  after_initialize :init

  def init
    self.created_at ||= DateTime.now
  end

  # Mark this job as finished
  def complete!
    self.complete = true
    save!
  end
end
