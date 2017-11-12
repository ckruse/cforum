require 'rails_helper'

RSpec.describe User, type: :model do
  it 'is valid with username, email and password' do
    user = User.new(username: 'Luke Skywalker', email: 'l.skywalker@example.org', password: '123')
    expect(user).to be_valid
  end

  it 'is invalid without username' do
    user = User.new(email: 'l.skywalker@example.org', password: '123')
    expect(user).to be_invalid
  end

  it 'is invalid without email' do
    user = User.new(username: 'Luke Skywalker', password: '123')
    expect(user).to be_invalid
  end

  it 'is invalid without password on create' do
    user = User.new(username: 'Luke Skywalker', email: 'l.skywalker@example.org')
    expect(user).to be_invalid
  end

  it 'is invalid with duplicate username' do
    User.create!(username: 'Luke Skywalker', email: 'l.skywalker1@example.org', password: '123')
    user = User.new(username: 'Luke Skywalker', email: 'l.skywalker@example.org', password: '123')
    expect(user).to be_invalid
  end

  it 'is invalid with duplicate email' do
    User.create!(username: 'Luke Skywalker 1', email: 'l.skywalker@example.org', password: '123')
    user = User.new(username: 'Luke Skywalker', email: 'l.skywalker@example.org', password: '123')
    expect(user).to be_invalid
  end

  describe 'conf' do
    it "returns default when config option isn't set" do
      user = User.new(settings: Setting.new(options: {}))
      expect(user.conf('highlight_self')).to eq ConfigManager::DEFAULTS['highlight_self']
    end

    it 'returns default when no config exists' do
      user = User.new
      expect(user.conf('highlight_self')).to eq ConfigManager::DEFAULTS['highlight_self']
    end

    it 'returns config value when set' do
      user = User.new(settings: Setting.new(options: { 'highlight_self' => 'no' }))
      expect(user.conf('highlight_self')).to eq 'no'
    end
  end

  describe 'badge?' do
    it 'returns true when user has badge' do
      user = User.new
      user.badges = [Badge.new(badge_type: 'silver medal')]
      expect(user.badge?('silver medal')).to be true
    end

    it "returns false when user doesn't have that badge" do
      user = User.new
      user.badges = [Badge.new(badge_type: 'silver medal')]
      expect(user.badge?('gold medal')).to be false
    end

    it "returns false when user hasn't got any badges" do
      user = User.new
      expect(user.badge?('silver medal')).to be false
    end
  end

  describe 'moderate?' do
    it 'returns true if user is admin' do
      expect(build(:user_admin).moderate?).to be true
    end

    it 'returns true if user has moderator badge' do
      expect(build(:user_moderator).moderate?).to be true
    end

    it 'returns false if forum is blank and user is not admin nor has moderator badge' do
      expect(build(:user).moderate?).to be false
    end

    it 'returns true if user is moderator for a specific forum' do
      perm = create(:forum_group_moderate_permission)
      user = create(:user)
      perm.group.users << user

      expect(user.moderate?(perm.forum)).to be true
    end

    it 'returns false if user is not moderator nor admin' do
      forum = create(:write_forum)
      user = build(:user)
      expect(user.moderate?(forum)).to be false
    end
  end

  describe 'moderator?' do
    it 'returns true if user is admin' do
      expect(User.new(admin: true).moderator?).to be true
    end

    it 'returns true if user has moderator badge' do
      user = User.new(badges: [Badge.new(badge_type: Badge::MODERATOR_TOOLS)])
      expect(user.moderator?).to be true
    end

    it 'returns true if user is in a admin group' do
      user = User.create!(username: 'Luke Skywalker',
                          email: 'l.skywalker@example.org',
                          password: '123')
      forum = Forum.create!(name: 'Aldebaran',
                            short_name: 'Aldebaran',
                            slug: 'aldebaran')
      group = Group.create!(name: 'Rebellion')
      group.users << user
      group.forums_groups_permissions << ForumGroupPermission.new(permission: ForumGroupPermission::MODERATE,
                                                                  forum: forum)

      expect(group).to be_valid
      group.save

      expect(user.moderator?).to be true
    end

    it 'returns false if not admin nor moderator badge nor moderator' do
      expect(User.new.moderator?).to be false
    end
  end

  describe 'write?' do
    it "returns true if forum's standard permission is write" do
      forum = build(:write_forum)
      user = build(:user)
      expect(user.write?(forum)).to be true
    end

    it "returns true if forum's standard permission is write for registered users" do
      forum = build(:known_write_forum)
      user = build(:user)
      expect(user.write?(forum)).to be true
    end

    it 'returns true if user is admin' do
      forum = build(:forum)
      user = build(:user_admin)
      expect(user.write?(forum)).to be true
    end

    it 'returns true if user has moderator badge' do
      forum = build(:forum)
      user = build(:user_moderator)
      expect(user.write?(forum)).to be true
    end

    it 'returns true if user is in group with write permissions' do
      perm = create(:forum_group_write_permission)
      user = create(:user)
      perm.group.users << user
      expect(user.write?(perm.forum)).to be true
    end

    it 'returns true if user is in group with moderator permissions' do
      perm = create(:forum_group_moderate_permission)
      user = create(:user)
      perm.group.users << user
      expect(user.write?(perm.forum)).to be true
    end

    it 'returns false otherwise' do
      forum = build(:read_forum)
      user = build(:user)
      expect(user.write?(forum)).to be false
    end
  end

  describe 'read?' do
    it "returns true if forum's standard permission is read" do
      forum = build(:read_forum)
      user = build(:user)
      expect(user.read?(forum)).to be true
    end

    it "returns true if forum's standard permission is write" do
      forum = build(:write_forum)
      user = build(:user)
      expect(user.read?(forum)).to be true
    end

    it "returns true if forum's standard permission is read for registered users" do
      forum = build(:known_read_forum)
      user = build(:user)
      expect(user.read?(forum)).to be true
    end

    it "returns true if forum's standard permission is write for registered users" do
      forum = build(:known_write_forum)
      user = build(:user)
      expect(user.read?(forum)).to be true
    end

    it 'returns true if user is admin' do
      forum = build(:forum)
      user = build(:user_admin)
      expect(user.read?(forum)).to be true
    end

    it 'returns true if user has moderator badge' do
      forum = build(:forum)
      user = build(:user_moderator)
      expect(user.read?(forum)).to be true
    end

    it 'returns true if user is in group with read permissions' do
      perm = create(:forum_group_permission)
      user = create(:user)
      perm.group.users << user
      expect(user.read?(perm.forum)).to be true
    end

    it 'returns true if user is in group with write permissions' do
      perm = create(:forum_group_write_permission)
      user = create(:user)
      perm.group.users << user
      expect(user.read?(perm.forum)).to be true
    end

    it 'returns true if user is in group with moderator permissions' do
      perm = create(:forum_group_moderate_permission)
      user = create(:user)
      perm.group.users << user
      expect(user.read?(perm.forum)).to be true
    end

    it 'returns false otherwise' do
      forum = build(:forum)
      user = build(:user)
      expect(user.read?(forum)).to be false
    end
  end

  describe 'score' do
    it 'returns the sum of scores for a user' do
      user = create(:user)
      Score.create!(user_id: user.user_id, value: 10)
      user.reload
      expect(user.score).to eq 10
    end

    it 'returns zero when user has no score' do
      user = create(:user)
      expect(user.score).to eq 0
    end
  end

  it 'does not include private attributes when rendering to json' do
    user = build(:user)
    user.authentication_token = '1234'

    json = user.as_json

    expect(json =~ /"email":/).to be_nil
    expect(json =~ /"authentication_token":/).to be_nil
  end

  it 'returns a unique list of badges' do
    badge = create(:badge)
    user = create(:user)

    user.badges << badge
    user.badges << badge

    expect(user.unique_badges).to eq [{ badge: badge, times: 2, created_at: user.badge_users.first.created_at }]
  end

  it 'returns an audit json string' do
    user = build(:user)
    expect(user.audit_json).to eq(user.as_json(include: :badges))
  end
end

# eof
