module AuditHelper
  def audit(object, action, creator = current_user)
    Auditing.create!(relation: object.class.table_name,
                     relid: object.send(object.class.primary_key),
                     act: action,
                     contents: object.try(:audit_json) || object.as_json,
                     user_id: creator.try(:user_id),
                     created_at: Time.zone.now)
  end
end

# eof
