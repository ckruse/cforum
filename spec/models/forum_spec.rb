require "rails_helper"

describe Forum do
  it "is valid with name, short_name and slug" do
    expect(Forum.new(name: 'Rebellion',
                       short_name: 'Rebellion',
                       slug: 'rebellion')).to be_valid
  end

  it "is invalid w/o name" do
    expect(Forum.new(short_name: 'Rebellion',
                       slug: 'rebellion')).to be_invalid
  end

  it "is invalid w/o short_name" do
    expect(Forum.new(name: 'Rebellion',
                       slug: 'rebellion')).to be_invalid
  end
  it "is invalid w/o slug" do
    expect(Forum.new(name: 'Rebellion',
                       short_name: 'Rebellion')).to be_invalid
  end

  it "is invalid with duplicate slug" do
    Forum.create!(name: 'Rebellion',
                    short_name: 'Rebellion',
                    slug: 'rebellion')
    expect(Forum.new(name: 'Rebellion',
                       short_name: 'Rebellion',
                       slug: 'rebellion')).to be_invalid
  end

  describe "moderator?" do
    let(:forum) { build(:write_forum) }

    it "returns false when user is blank" do
      expect(forum.moderator?(nil)).to be false
    end

    it "returns true when user is admin" do
      user = build(:user_admin)
      expect(forum.moderator?(user)).to be true
    end

    it "returns true when user has moderator badge" do
      user = create(:user_moderator)
      expect(forum.moderator?(user)).to be true
    end

    it "returns true if user is in group with moderator access" do
      forum.save
      perm = create(:forum_group_moderate_permission, forum: forum)
      user = create(:user)
      perm.group.users << user
      expect(forum.moderator?(user)).to be true
    end

    it "returns false otherwise" do
      user = build(:user)
      expect(forum.moderator?(user)).to be false
    end
  end

  describe "write?" do
    it "returns true if standard permission is write" do
      forum = build(:write_forum)
      expect(forum.write?(nil)).to be true
      expect(forum.write?(build(:user))).to be true
    end

    it "returns false if user is blank and standard permission is not write" do
      forum = build(:read_forum)
      expect(forum.write?(nil)).to be false
    end

    it "returns true if standard permission is known write" do
      forum = build(:known_write_forum)
      expect(forum.write?(nil)).to be false
      expect(forum.write?(build(:user))).to be true
    end

    it "returns true if user is admin" do
      forum = build(:read_forum)
      expect(forum.write?(build(:user_admin))).to be true
    end

    it "returns true if user has moderator badge" do
      forum = build(:read_forum)
      expect(forum.write?(create(:user_moderator))).to be true
    end

    it "returns true if user is in group with write permission" do
      perm = create(:forum_group_write_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.write?(user)).to be true
    end

    it "returns true if user is in group with moderate permission" do
      perm = create(:forum_group_moderate_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.write?(user)).to be true
    end

    it "returns false otherwise" do
      forum = build(:read_forum)
      expect(forum.write?(build(:user))).to be false
    end
  end

  describe "read?" do
    it "returns true if standard permission is read" do
      forum = build(:read_forum)
      expect(forum.read?(nil)).to be true
      expect(forum.read?(build(:user))).to be true
    end

    it "returns false if user is blank and standard permission is not read" do
      forum = build(:forum)
      expect(forum.read?(nil)).to be false
    end

    it "returns true if standard permission is known read" do
      forum = build(:known_read_forum)
      expect(forum.read?(build(:user))).to be true
    end

    it "returns true if standard permission is known write" do
      forum = build(:known_write_forum)
      expect(forum.read?(build(:user))).to be true
    end

    it "returns true if user is admin" do
      forum = build(:forum)
      expect(forum.read?(build(:user_admin))).to be true
    end

    it "returns true if user has moderator badge" do
      forum = build(:forum)
      expect(forum.read?(create(:user_moderator))).to be true
    end

    it "returns true if user is in group with read permission" do
      perm = create(:forum_group_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.read?(user)).to be true
    end

    it "returns true if user is in group with write permission" do
      perm = create(:forum_group_write_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.read?(user)).to be true
    end

    it "returns true if user is in group with moderate permission" do
      perm = create(:forum_group_moderate_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.read?(user)).to be true
    end

    it "returns false otherwise" do
      forum = build(:forum)
      expect(forum.read?(build(:user))).to be false
    end
  end
end
