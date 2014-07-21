class SupportersActionJob < ActiveRecord::Base
  attr_accessible :complete, :email_address, :first_name, :last_name, :operation, :page_name

  # Mark this job as finished
  def complete!
    self.complete = true
    save!
  end
end
