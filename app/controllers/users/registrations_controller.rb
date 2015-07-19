# -*- coding: utf-8 -*-

class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super
    audit(resource, 'create') if resource.errors.empty?
  end
end

# eof
