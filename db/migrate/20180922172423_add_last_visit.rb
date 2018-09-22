class AddLastVisit < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :last_visit, :timestamp
  end
end
