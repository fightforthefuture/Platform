class AddCreatedAtToSupportersActionJob < ActiveRecord::Migration
  def change
    add_column :supporters_action_job, :created_at, :datetime
  end
end
