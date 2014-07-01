class RenameOptInFields < ActiveRecord::Migration
  def change
    rename_column :user_activity_events, :opt_in_ip_address, :ip_address
    rename_column :user_activity_events, :opt_in_url, :referer_url
  end
end
