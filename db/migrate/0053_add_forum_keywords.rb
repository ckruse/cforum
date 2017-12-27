class AddForumKeywords < ActiveRecord::Migration[5.0]
  def change
    change_table(:forums) do |t|
      t.string :keywords
    end
  end
end

# eof
