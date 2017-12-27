class AddIpToMessages < ActiveRecord::Migration[5.0]
  def change
    change_table(:messages) do |t|
      t.string :ip
    end
  end
end

# eof
