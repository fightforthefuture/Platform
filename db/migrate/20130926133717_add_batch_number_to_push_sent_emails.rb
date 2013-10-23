class AddBatchNumberToPushSentEmails < ActiveRecord::Migration
  def change
    add_column :push_sent_emails, :batch_number, :integer
  end
end
