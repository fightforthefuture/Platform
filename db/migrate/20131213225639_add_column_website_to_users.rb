class AddColumnWebsiteToUsers < ActiveRecord::Migration
  def change
    add_column :users, :website, :string, :limit => 512
  end
end
