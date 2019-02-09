class Users::RegistrationsController < Devise::RegistrationsController
  invisible_captcha only: [:create], honeypot: :lastname
end

# eof
