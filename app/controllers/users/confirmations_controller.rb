class Users::ConfirmationsController < Devise::ConfirmationsController
  def show
    super
    audit(resource, 'confirm') if resource.errors.empty?
  end
end

# eof
