class Users::RegistrationsController < Devise::RegistrationsController
  def create
    vals = [('a'..'z'), ('A'..'Z')].map(&:to_a).flatten

    super do |user|
      user.confirmation_captcha = (0..3).map { vals[rand(vals.length)] }.join
      user.save!
    end
  end
end
