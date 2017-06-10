require 'rails_helper'

RSpec.describe Forum, type: :model do
  it 'is valid with name, short_name and slug' do
    expect(Forum.new(name: 'Rebellion',
                     short_name: 'Rebellion',
                     slug: 'rebellion')).to be_valid
  end

  it 'is invalid w/o name' do
    expect(Forum.new(short_name: 'Rebellion',
                     slug: 'rebellion')).to be_invalid
  end

  it 'is invalid w/o short_name' do
    expect(Forum.new(name: 'Rebellion',
                     slug: 'rebellion')).to be_invalid
  end
  it 'is invalid w/o slug' do
    expect(Forum.new(name: 'Rebellion',
                     short_name: 'Rebellion')).to be_invalid
  end

  it 'is invalid with duplicate slug' do
    Forum.create!(name: 'Rebellion',
                  short_name: 'Rebellion',
                  slug: 'rebellion')
    expect(Forum.new(name: 'Rebellion',
                     short_name: 'Rebellion',
                     slug: 'rebellion')).to be_invalid
  end

  describe 'moderator?' do
    let(:forum) { build(:write_forum) }

    it 'returns false when user is blank' do
      expect(forum.moderator?(nil)).to be false
    end

    it 'returns true when user is admin' do
      user = build(:user_admin)
      expect(forum.moderator?(user)).to be true
    end

    it 'returns true when user has moderator badge' do
      user = create(:user_moderator)
      expect(forum.moderator?(user)).to be true
    end

    it 'returns true if user is in group with moderator access' do
      forum.save
      perm = create(:forum_group_moderate_permission, forum: forum)
      user = create(:user)
      perm.group.users << user
      expect(forum.moderator?(user)).to be true
    end

    it 'returns false otherwise' do
      user = build(:user)
      expect(forum.moderator?(user)).to be false
    end
  end

  describe 'write?' do
    it 'returns true if standard permission is write' do
      forum = build(:write_forum)
      expect(forum.write?(nil)).to be true
      expect(forum.write?(build(:user))).to be true
    end

    it 'returns false if user is blank and standard permission is not write' do
      forum = build(:read_forum)
      expect(forum.write?(nil)).to be false
    end

    it 'returns true if standard permission is known write' do
      forum = build(:known_write_forum)
      expect(forum.write?(nil)).to be false
      expect(forum.write?(build(:user))).to be true
    end

    it 'returns true if user is admin' do
      forum = build(:read_forum)
      expect(forum.write?(build(:user_admin))).to be true
    end

    it 'returns true if user has moderator badge' do
      forum = build(:read_forum)
      expect(forum.write?(create(:user_moderator))).to be true
    end

    it 'returns true if user is in group with write permission' do
      perm = create(:forum_group_write_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.write?(user)).to be true
    end

    it 'returns true if user is in group with moderate permission' do
      perm = create(:forum_group_moderate_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.write?(user)).to be true
    end

    it 'returns false otherwise' do
      forum = build(:read_forum)
      expect(forum.write?(build(:user))).to be false
    end
  end

  describe 'read?' do
    it 'returns true if standard permission is read' do
      forum = build(:read_forum)
      expect(forum.read?(nil)).to be true
      expect(forum.read?(build(:user))).to be true
    end

    it 'returns false if user is blank and standard permission is not read' do
      forum = build(:forum)
      expect(forum.read?(nil)).to be false
    end

    it 'returns true if standard permission is known read' do
      forum = build(:known_read_forum)
      expect(forum.read?(build(:user))).to be true
    end

    it 'returns true if standard permission is known write' do
      forum = build(:known_write_forum)
      expect(forum.read?(build(:user))).to be true
    end

    it 'returns true if user is admin' do
      forum = build(:forum)
      expect(forum.read?(build(:user_admin))).to be true
    end

    it 'returns true if user has moderator badge' do
      forum = build(:forum)
      expect(forum.read?(create(:user_moderator))).to be true
    end

    it 'returns true if user is in group with read permission' do
      perm = create(:forum_group_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.read?(user)).to be true
    end

    it 'returns true if user is in group with write permission' do
      perm = create(:forum_group_write_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.read?(user)).to be true
    end

    it 'returns true if user is in group with moderate permission' do
      perm = create(:forum_group_moderate_permission)
      user = create(:user)
      perm.group.users << user
      expect(perm.forum.read?(user)).to be true
    end

    it 'returns false otherwise' do
      forum = build(:forum)
      expect(forum.read?(build(:user))).to be false
    end
  end

  describe 'visible sql' do
    it 'generates SQL returning only public forums' do
      forums = [create(:write_forum), create(:known_write_forum),
                create(:read_forum), create(:known_read_forum),
                create(:forum), create(:moderate_forum)]

      ret_forums = Forum.visible_forums.reorder(:forum_id)

      expect(ret_forums.to_a).to eq([forums[0], forums[2], forums[5]])
    end

    it 'generates SQL returning forums visible to user' do
      forums = [create(:write_forum), create(:known_write_forum),
                create(:read_forum), create(:known_read_forum),
                create(:forum), create(:moderate_forum)]
      u = create(:user)

      ret_forums = Forum.visible_forums(u).reorder(:forum_id)

      expect(ret_forums.to_a).to eq([forums[0], forums[1], forums[2], forums[3], forums[5]])
    end

    it 'generates SQL returning all forums for admin user' do
      forums = [create(:write_forum), create(:known_write_forum),
                create(:read_forum), create(:known_read_forum),
                create(:forum), create(:moderate_forum)]
      u = create(:user_admin)

      ret_forums = Forum.visible_forums(u).reorder(:forum_id)

      expect(ret_forums.to_a).to eq(forums)
    end

    it 'generates SQL for group with read permissions' do
      forums = [create(:forum), create(:forum)]
      user = create(:user)

      group = Group.create!(name: 'foo')
      group.users << user
      group.forums_groups_permissions.create!(forum_id: forums.first.forum_id,
                                              permission: ForumGroupPermission::WRITE)

      ret_forums = Forum.visible_forums(user).reorder(:forum_id)
      expect(ret_forums.to_a).to eq([forums.first])
    end
  end
end
