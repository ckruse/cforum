# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

s = CfSetting.new(
  value: %w[
    CATEGORY1
    CATEGORY2
    CATEGORY3
    CATEGORY4
  ]
)
s.id = 'categories'
s.save

s = CfSetting.new(
  value: true
)
s.id = 'use_archive'
s.save
