class AddUniqueIndexOnMediaFilename < ActiveRecord::Migration[5.1]
  def change
    add_index :media, :filename, unique: true
  end
end
