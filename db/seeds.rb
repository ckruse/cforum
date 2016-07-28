# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# s = Setting.new(
#   value: %w[
#     CATEGORY1
#     CATEGORY2
#     CATEGORY3
#     CATEGORY4
#   ]
# )
# s.id = 'categories'
# s.save

# s = Setting.new(
#   value: true
# )
# s.id = 'use_archive'
# s.save

unless User.where(username: "admin").exists?
  usr = User.new(username: 'admin', email: 'foo@example.org', admin: true)
  usr.skip_confirmation!
  usr.save!(validate: false)
end

unless Forum.where(slug: "forum-1").exists?
  Forum.create!(name: "Forum 1", slug: "forum-1", short_name: "Forum 1", standard_permission: "write")
end

# eof
