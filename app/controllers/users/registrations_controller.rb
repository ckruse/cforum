class Users::RegistrationsController < Devise::RegistrationsController
  invisible_captcha only: [:create]
end

# eof
