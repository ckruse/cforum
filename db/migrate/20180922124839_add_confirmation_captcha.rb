class AddConfirmationCaptcha < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :confirmation_captcha, :string
  end
end
