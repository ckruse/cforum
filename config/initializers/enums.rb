ENUM_TYPES = %w(badge_medal_type_t badge_type_t)

ENUM_TYPES.each do |type|
  ::ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::OID.alias_type type.to_s, 'text'
end
