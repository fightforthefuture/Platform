class AddCreatedAtToSupportersActionJobs < ActiveRecord::Migration
  def change
    add_column :supporters_action_jobs, :created_at, :datetime
  end
end
