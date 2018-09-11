class AddDisabledToBadges < ActiveRecord::Migration[5.1]
  def change
    add_column :badges_users, :active, :boolean, default: true, null: false
  end
end
