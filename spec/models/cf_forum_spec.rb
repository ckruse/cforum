require "rails_helper"

describe CfForum do
  it "is valid with name, short_name and slug" do
    expect(CfForum.new(name: 'Rebellion',
                       short_name: 'Rebellion',
                       slug: 'rebellion')).to be_valid
  end

  it "is invalid w/o name" do
    expect(CfForum.new(short_name: 'Rebellion',
                       slug: 'rebellion')).to be_invalid
  end

  it "is invalid w/o short_name" do
    expect(CfForum.new(name: 'Rebellion',
                       slug: 'rebellion')).to be_invalid
  end
  it "is invalid w/o slug" do
    expect(CfForum.new(name: 'Rebellion',
                       short_name: 'Rebellion')).to be_invalid
  end

  it "is invalid with duplicate slug" do
    CfForum.create!(name: 'Rebellion',
                    short_name: 'Rebellion',
                    slug: 'rebellion')
    expect(CfForum.new(name: 'Rebellion',
                       short_name: 'Rebellion',
                       slug: 'rebellion')).to be_invalid
  end

  describe "moderator?" do
    let(:forum) { build(:cf_write_forum) }

    it "returns false when user is blank" do
      expect(forum.moderator?(nil)).to be false
    end

    it "returns true when user is admin" do
      user = build(:cf_user_admin)
      expect(forum.moderator?(user)).to be true
    end

    it "returns true when user has moderator badge" do
      user = create(:cf_user_moderator)
      expect(forum.moderator?(user)).to be true
    end

    it "returns true if user is in group with moderator access" do
      forum.save
      perm = create(:cf_forum_group_moderate_permission, forum: forum)
      user = create(:cf_user)
      perm.group.users << user
      expect(forum.moderator?(user)).to be true
    end

    it "returns false otherwise" do
      user = build(:cf_user)
      expect(forum.moderator?(user)).to be false
    end
  end

  describe "write?" do
    it "returns true if standard permission is write" do
      forum = build(:cf_write_forum)
      expect(forum.write?(nil)).to be true
      expect(forum.write?(build(:cf_user))).to be true
    end

    it "returns false if user is blank and standard permission is not write" do
      forum = build(:cf_read_forum)
      expect(forum.write?(nil)).to be false
    end

    it "returns true if standard permission is known write" do
      forum = build(:cf_known_write_forum)
      expect(forum.write?(nil)).to be false
      expect(forum.write?(build(:cf_user))).to be true
    end

    it "returns true if user is admin" do
      forum = build(:cf_read_forum)
      expect(forum.write?(build(:cf_user_admin))).to be true
    end

    it "returns true if user has moderator badge" do
      forum = build(:cf_read_forum)
      expect(forum.write?(create(:cf_user_moderator))).to be true
    end

    it "returns true if user is in group with write permission" do
      perm = create(:cf_forum_group_write_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(perm.forum.write?(user)).to be true
    end

    it "returns true if user is in group with moderate permission" do
      perm = create(:cf_forum_group_moderate_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(perm.forum.write?(user)).to be true
    end

    it "returns false otherwise" do
      forum = build(:cf_read_forum)
      expect(forum.write?(build(:cf_user))).to be false
    end
  end

  describe "read?" do
    it "returns true if standard permission is read" do
      forum = build(:cf_read_forum)
      expect(forum.read?(nil)).to be true
      expect(forum.read?(build(:cf_user))).to be true
    end

    it "returns false if user is blank and standard permission is not read" do
      forum = build(:cf_forum)
      expect(forum.read?(nil)).to be false
    end

    it "returns true if standard permission is known read" do
      forum = build(:cf_known_read_forum)
      expect(forum.read?(build(:cf_user))).to be true
    end

    it "returns true if standard permission is known write" do
      forum = build(:cf_known_write_forum)
      expect(forum.read?(build(:cf_user))).to be true
    end

    it "returns true if user is admin" do
      forum = build(:cf_forum)
      expect(forum.read?(build(:cf_user_admin))).to be true
    end

    it "returns true if user has moderator badge" do
      forum = build(:cf_forum)
      expect(forum.read?(create(:cf_user_moderator))).to be true
    end

    it "returns true if user is in group with read permission" do
      perm = create(:cf_forum_group_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(perm.forum.read?(user)).to be true
    end

    it "returns true if user is in group with write permission" do
      perm = create(:cf_forum_group_write_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(perm.forum.read?(user)).to be true
    end

    it "returns true if user is in group with moderate permission" do
      perm = create(:cf_forum_group_moderate_permission)
      user = create(:cf_user)
      perm.group.users << user
      expect(perm.forum.read?(user)).to be true
    end

    it "returns false otherwise" do
      forum = build(:cf_forum)
      expect(forum.read?(build(:cf_user))).to be false
    end
  end
end
