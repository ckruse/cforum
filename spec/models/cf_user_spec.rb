require "rails_helper"

describe CfUser do
  it "is valid with username, email and password" do
    user = CfUser.new(username: 'Luke Skywalker', email: 'l.skywalker@example.org', password: '123')
    expect(user).to be_valid
  end

  it "is invalid without username" do
    user = CfUser.new(email: 'l.skywalker@example.org', password: '123')
    expect(user).to be_invalid
  end

  it "is invalid without email" do
    user = CfUser.new(username: 'Luke Skywalker', password: '123')
    expect(user).to be_invalid
  end

  it "is invalid without password on create" do
    user = CfUser.new(username: 'Luke Skywalker', email: 'l.skywalker@example.org')
    expect(user).to be_invalid
  end

  it "is invalid with duplicate username" do
    CfUser.create!(username: 'Luke Skywalker', email: 'l.skywalker1@example.org', password: '123')
    user = CfUser.new(username: 'Luke Skywalker', email: 'l.skywalker@example.org', password: '123')
    expect(user).to be_invalid
  end

  it "is invalid with duplicate email" do
    CfUser.create!(username: 'Luke Skywalker 1', email: 'l.skywalker@example.org', password: '123')
    user = CfUser.new(username: 'Luke Skywalker', email: 'l.skywalker@example.org', password: '123')
    expect(user).to be_invalid
  end

  describe "conf" do
    it "returns default when config option isn't set" do
      user = CfUser.new(settings: CfSetting.new(options: {}))
      expect(user.conf('mark_read_moment')).to eq ConfigManager::DEFAULTS['mark_read_moment']
    end

    it "returns default when no config exists" do
      user = CfUser.new
      expect(user.conf('mark_read_moment')).to eq ConfigManager::DEFAULTS['mark_read_moment']
    end

    it "returns config value when set" do
      user = CfUser.new(settings: CfSetting.new(options: {'mark_read_moment' => 'after'}))
      expect(user.conf('mark_read_moment')).to eq 'after'
    end
  end

  describe "has_badge?" do
    it "returns true when user has badge" do
      user = CfUser.new
      user.badges = [CfBadge.new(badge_type: 'silver medal')]
      expect(user.has_badge?('silver medal')).to be true
    end

    it "returns false when user doesn't have that badge" do
      user = CfUser.new
      user.badges = [CfBadge.new(badge_type: 'silver medal')]
      expect(user.has_badge?('gold medal')).to be false
    end

    it "returns false when user hasn't got any badges" do
      user = CfUser.new
      expect(user.has_badge?('silver medal')).to be false
    end
  end

  describe "moderate?" do
    it "returns true if user is admin" do
      expect(build(:cf_user_admin).moderate?).to be true
    end

    it "returns true if user has moderator badge" do
      expect(build(:cf_user_moderator).moderate?).to be true
    end

    it "returns false if forum is blank and user is not admin nor has moderator badge" do
      expect(build(:cf_user).moderate?).to be false
    end

    it "returns true if user is moderator for a specific forum" do
      perm = create(:cf_forum_group_moderate_permission)
      user = create(:cf_user)
      perm.group.users << user

      expect(user.moderate?(perm.forum)).to be true
    end

    it "returns false if user is not moderator nor admin" do
      forum = create(:cf_write_forum)
      user = build(:cf_user)
      expect(user.moderate?(forum)).to be false
    end
  end

  describe "moderator?" do
    it "returns true if user is admin" do
      expect(CfUser.new(admin: true).moderator?).to be true
    end

    it "returns true if user has moderator badge" do
      user = CfUser.new(badges: [CfBadge.new(badge_type: RightsHelper::MODERATOR_TOOLS)])
      expect(user.moderator?).to be true
    end

    it "returns true if user is in a admin group" do
      user = CfUser.create!(username: "Luke Skywalker",
                            email: "l.skywalker@example.org",
                            password: '123')
      forum = CfForum.create!(name: 'Aldebaran',
                              short_name: 'Aldebaran',
                              slug: 'aldebaran')
      group = CfGroup.create!(name: 'Rebellion')
      group.users << user
      group.forums_groups_permissions << CfForumGroupPermission.new(permission: CfForumGroupPermission::ACCESS_MODERATE,
                                                                    forum: forum)

      expect(group).to be_valid
      group.save

      expect(user.moderator?).to be true
    end

    it "returns false if not admin nor moderator badge nor moderator" do
      expect(CfUser.new.moderator?).to be false
    end
  end

  describe "write?" do
    it "returns true if forum's standard permission is write" do
      forum = build(:cf_write_forum)
      user = build(:cf_user)
      expect(user.write?(forum)).to be true
    end

    it "returns true if forum's standard permission is write for registered users" do
      forum = build(:cf_known_write_forum)
      user = build(:cf_user)
      expect(user.write?(forum)).to be true
    end

    it "returns true if user is admin" do
      forum = build(:cf_forum)
      user = build(:cf_user_admin)
      expect(user.write?(forum)).to be true
    end

    it "returns true if user has moderator badge" do
      forum = build(:cf_forum)
      user = build(:cf_user_moderator)
      expect(user.write?(forum)).to be true
    end

    it "returns true if user is in group with write permissions" do
      perm = create(:cf_forum_group_write_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(user.write?(perm.forum)).to be true
    end

    it "returns true if user is in group with moderator permissions" do
      perm = create(:cf_forum_group_moderate_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(user.write?(perm.forum)).to be true
    end

    it "returns false otherwise" do
      forum = build(:cf_read_forum)
      user = build(:cf_user)
      expect(user.write?(forum)).to be false
    end
  end

  describe "read?" do
    it "returns true if forum's standard permission is read" do
      forum = build(:cf_read_forum)
      user = build(:cf_user)
      expect(user.read?(forum)).to be true
    end

    it "returns true if forum's standard permission is write" do
      forum = build(:cf_write_forum)
      user = build(:cf_user)
      expect(user.read?(forum)).to be true
    end

    it "returns true if forum's standard permission is read for registered users" do
      forum = build(:cf_known_read_forum)
      user = build(:cf_user)
      expect(user.read?(forum)).to be true
    end

    it "returns true if forum's standard permission is write for registered users" do
      forum = build(:cf_known_write_forum)
      user = build(:cf_user)
      expect(user.read?(forum)).to be true
    end

    it "returns true if user is admin" do
      forum = build(:cf_forum)
      user = build(:cf_user_admin)
      expect(user.read?(forum)).to be true
    end

    it "returns true if user has moderator badge" do
      forum = build(:cf_forum)
      user = build(:cf_user_moderator)
      expect(user.read?(forum)).to be true
    end

    it "returns true if user is in group with read permissions" do
      perm = create(:cf_forum_group_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(user.read?(perm.forum)).to be true
    end

    it "returns true if user is in group with write permissions" do
      perm = create(:cf_forum_group_write_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(user.read?(perm.forum)).to be true
    end

    it "returns true if user is in group with moderator permissions" do
      perm = create(:cf_forum_group_moderate_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(user.read?(perm.forum)).to be true
    end

    it "returns false otherwise" do
      forum = build(:cf_forum)
      user = build(:cf_user)
      expect(user.read?(forum)).to be false
    end
  end

  describe "score" do
    it "returns the sum of scores for a user" do
      user = create(:cf_user)
      CfScore.create!(user_id: user.user_id, value: 10)
      expect(user.score).to eq 10
    end

    it "returns zero when user has no score" do
      user = create(:cf_user)
      expect(user.score).to eq 0
    end
  end
end
