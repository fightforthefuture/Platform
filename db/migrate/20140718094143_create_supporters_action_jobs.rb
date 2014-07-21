class CreateSupportersActionJobs < ActiveRecord::Migration
  def change
    create_table :supporters_action_jobs do |t|
      t.string :operation, null: false
      t.string :first_name
      t.string :last_name
      t.string :email_address
      t.string :page_name
      t.boolean :complete, default: false

      t.timestamps
    end
  end
end
