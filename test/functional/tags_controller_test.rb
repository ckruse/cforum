# -*- coding: utf-8 -*-

require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  test "should show empty index" do
    forum = FactoryGirl.create(:cf_write_forum)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_empty assigns(:tags)
  end

  test "should show index" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum: forum)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_not_empty assigns(:tags)
  end

  test "should show index with search" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum: forum)

    get :index, {curr_forum: forum.slug, s: tag.tag_name[0..2]}
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_not_empty assigns(:tags)
  end

  test "should show index with tags" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum: forum)
    tag1 = FactoryGirl.create(:cf_tag, forum: forum)

    get :index, {curr_forum: forum.slug, tags: tag.tag_name + "," + tag1.tag_name}
    assert_response :success
    assert_not_empty assigns(:tags)
  end

  test "should not show because does not exist" do
    forum = FactoryGirl.create(:cf_write_forum)
    assert_raise ActiveRecord::RecordNotFound do
      get :show, curr_forum: forum.slug, id: 'lululu'
    end
  end

  test "sould not show because forum does not exist" do
    assert_raise CForum::NotFoundException do
      get :show, curr_forum: 'lalalal', id: 'lululu'
    end
  end

  test "should not show because of wrong forum" do
    tag = FactoryGirl.create(:cf_tag)
    forum = FactoryGirl.create(:cf_write_forum)

    assert_raise ActiveRecord::RecordNotFound do
      get :show, curr_forum: forum.slug, id: tag.slug
    end
  end

  test "should show" do
    tag = FactoryGirl.create(:cf_tag)

    get :show, curr_forum: tag.forum.slug, id: tag.slug
    assert_response :success
    assert_not_nil assigns(:tag)
  end

  test "should autocomplete" do
    tag = FactoryGirl.create(:cf_tag)
    get :autocomplete, {curr_forum: tag.forum.slug, s: tag.tag_name[0..3]}
    assert_response :success
    assert_not_empty assigns(:tags_list)
  end

  test "autocomplete should not fail wo search param" do
    tag = FactoryGirl.create(:cf_tag)
    get :autocomplete, {curr_forum: tag.forum.slug}
    assert_response :success
    assert_not_empty assigns(:tags_list)
  end

  test "should find synonym" do
    tag = FactoryGirl.create(:cf_tag)
    tag.synonyms.create!(synonym: 'Abcdef', forum_id: tag.forum.forum_id)

    get :autocomplete, {curr_forum: tag.forum.slug, s: "aBc"}
    assert_response :success
    assert_not_empty assigns(:tags_list)
  end


  test "should not show new as anonymous" do
    forum = FactoryGirl.create(:cf_write_forum)

    assert_raise CForum::ForbiddenException do
      get :new, curr_forum: forum.slug
    end

    forum = FactoryGirl.create(:cf_read_forum)

    assert_raise CForum::ForbiddenException do
      get :new, curr_forum: forum.slug
    end
  end

  test "should not show new wo badge" do
    forum = FactoryGirl.create(:cf_write_forum)
    usr = FactoryGirl.create(:cf_user, admin: false)

    sign_in usr

    assert_raise CForum::ForbiddenException do
      get :new, curr_forum: forum.slug
    end

    forum = FactoryGirl.create(:cf_read_forum)

    assert_raise CForum::ForbiddenException do
      get :new, curr_forum: forum.slug
    end
  end

  test "should show new with badge" do
    forum = FactoryGirl.create(:cf_write_forum)
    usr = FactoryGirl.create(:cf_user, admin: false)

    begin
      b = FactoryGirl.create(:cf_badge, badge_type: 'create_tag')
    rescue
      b = CfBadge.where(badge_type: 'create_tag').first
    end

    usr.badges_users.create!(badge: b)

    sign_in usr

    assert_nothing_raised do
      get :new, curr_forum: forum.slug
      assert_response :success
    end
  end

  test "should show new as admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)

    sign_in usr

    assert_nothing_raised do
      get :new, curr_forum: forum.slug
      assert_response :success
    end
  end


  test "should not create as anonymous" do
    forum = FactoryGirl.create(:cf_write_forum)

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        post :create, curr_forum: forum.slug, cf_tag: {tag_name: 'Tag Lala'}
      end
    end

    forum = FactoryGirl.create(:cf_read_forum)

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        post :create, curr_forum: forum.slug, cf_tag: {tag_name: 'Tag Lala'}
      end
    end
  end

  test "should not create wo badge" do
    forum = FactoryGirl.create(:cf_write_forum)
    usr = FactoryGirl.create(:cf_user, admin: false)

    sign_in usr

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        post :create, curr_forum: forum.slug, cf_tag: {tag_name: 'Tag Lala'}
      end
    end

    forum = FactoryGirl.create(:cf_read_forum)

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        post :create, curr_forum: forum.slug, cf_tag: {tag_name: 'Tag Lala'}
      end
    end
  end

  test "should create with badge" do
    forum = FactoryGirl.create(:cf_write_forum)
    usr = FactoryGirl.create(:cf_user, admin: false)

    begin
      b = FactoryGirl.create(:cf_badge, badge_type: 'create_tag')
    rescue
      b = CfBadge.where(badge_type: 'create_tag').first
    end

    usr.badges_users.create!(badge: b)

    sign_in usr

    assert_nothing_raised do
      assert_difference 'CfTag.count', 1 do
        post :create, curr_forum: forum.slug, cf_tag: {tag_name: 'Tag Lala'}
      end
      assert_redirected_to tags_url(forum.slug)
    end
  end

  test "should create as admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)

    sign_in usr

    assert_nothing_raised do
      assert_difference 'CfTag.count', 1 do
        post :create, curr_forum: forum.slug, cf_tag: {tag_name: 'Tag Lala'}
        assert_redirected_to tags_url(forum.slug)
      end
    end
  end

  test "should not create with invalid tag" do
    forum = FactoryGirl.create(:cf_write_forum)
    usr = FactoryGirl.create(:cf_user, admin: true)

    sign_in usr

    assert_nothing_raised do
      assert_no_difference 'CfTag.count' do
        post :create, curr_forum: forum.slug, cf_tag: {tag_name: 'a'}
        assert_response :success
      end
    end
  end



  test "should not show edit as anonymous" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_raise CForum::ForbiddenException do
      get :edit, curr_forum: tag.forum.slug, id: tag.slug
    end

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_raise CForum::ForbiddenException do
      get :edit, curr_forum: tag.forum.slug, id: tag.slug
    end
  end

  test "should not show edit wo admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: false)

    sign_in usr

    assert_raise CForum::ForbiddenException do
      get :edit, curr_forum: tag.forum.slug, id: tag.slug
    end

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_raise CForum::ForbiddenException do
      get :edit, curr_forum: forum.slug, id: tag.slug
    end
  end

  test "should show edit as admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: true)

    sign_in usr

    assert_nothing_raised do
      get :edit, curr_forum: forum.slug, id: tag.slug
      assert_response :success
    end
  end



  test "should not update as anonymous" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    n = tag.tag_name

    assert_raise CForum::ForbiddenException do
      patch :update, curr_forum: forum.slug, id: tag.slug, cf_tag: {tag_name: 'Tag Lala new'}
    end

    tag.reload
    assert_equal n, tag.tag_name

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    n = tag.tag_name

    assert_raise CForum::ForbiddenException do
      patch :update, curr_forum: forum.slug, id: tag.slug, cf_tag: {tag_name: 'Tag Lala new'}
    end

    tag.reload
    assert_equal n, tag.tag_name
  end

  test "should not update wo admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    n = tag.tag_name
    usr = FactoryGirl.create(:cf_user, admin: false)

    sign_in usr

    assert_raise CForum::ForbiddenException do
      patch :update, curr_forum: forum.slug, id: tag.slug, cf_tag: {tag_name: 'Tag Lala new'}
    end

    tag.reload
    assert_equal n, tag.tag_name

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    n = tag.tag_name

    assert_raise CForum::ForbiddenException do
      patch :update, curr_forum: forum.slug, id: tag.slug, cf_tag: {tag_name: 'Tag Lala new'}
    end

    tag.reload
    assert_equal n, tag.tag_name
  end

  test "should update as admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: true)

    sign_in usr

    assert_nothing_raised do
      patch :update, curr_forum: forum.slug, id: tag.slug, cf_tag: {tag_name: 'Tag Lala new'}
      assert_redirected_to tags_url(forum.slug)
    end

    tag.reload
    assert_equal 'Tag Lala new', tag.tag_name
    assert_equal 'tag-lala-new', tag.slug
  end

  test "should not update with invalid tag" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: true)

    n = tag.tag_name
    s = tag.slug

    sign_in usr

    assert_nothing_raised do
      patch :update, curr_forum: forum.slug, id: tag.slug, cf_tag: {tag_name: 'a'}
      assert_response :success
    end

    tag.reload

    assert_equal n, tag.tag_name
    assert_equal s, tag.slug
  end



  test "should not destroy as anonymous" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        delete :destroy, curr_forum: forum.slug, id: tag.slug
      end
    end

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        delete :destroy, curr_forum: forum.slug, id: tag.slug
      end
    end
  end

  test "should not destroy wo admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: false)

    sign_in usr

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        delete :destroy, curr_forum: forum.slug, id: tag.slug
      end
    end

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        delete :destroy, curr_forum: forum.slug, id: tag.slug
      end
    end
  end

  test "should destroy as admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: true)

    sign_in usr

    assert_difference "CfTag.count", -1 do
      assert_nothing_raised do
        delete :destroy, curr_forum: forum.slug, id: tag.slug
        assert_redirected_to tags_url(forum.slug)
      end
    end
  end



  test "should not show merge as anonymous" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_raise CForum::ForbiddenException do
      get :merge, curr_forum: tag.forum.slug, id: tag.slug
    end

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_raise CForum::ForbiddenException do
      get :merge, curr_forum: tag.forum.slug, id: tag.slug
    end
  end

  test "should not show merge wo admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: false)

    sign_in usr

    assert_raise CForum::ForbiddenException do
      get :merge, curr_forum: tag.forum.slug, id: tag.slug
    end

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_raise CForum::ForbiddenException do
      get :merge, curr_forum: forum.slug, id: tag.slug
    end
  end

  test "should show merge as admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: true)

    sign_in usr

    assert_nothing_raised do
      get :merge, curr_forum: forum.slug, id: tag.slug
      assert_response :success
    end
  end




  test "should not do merge as anonymous" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    tag1 = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        post :do_merge, curr_forum: forum.slug, id: tag.slug, merge_tag: tag1.tag_id
      end
    end

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    tag1 = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        post :do_merge, curr_forum: forum.slug, id: tag.slug, merge_tag: tag1.tag_id
      end
    end
  end

  test "should not do merge wo admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    tag1 = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: false)

    sign_in usr

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        post :do_merge, curr_forum: forum.slug, id: tag.slug, merge_tag: tag1.tag_id
      end
    end

    forum = FactoryGirl.create(:cf_read_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    tag1 = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)

    assert_no_difference 'CfTag.count' do
      assert_raise CForum::ForbiddenException do
        post :do_merge, curr_forum: forum.slug, id: tag.slug, merge_tag: tag1.tag_id
      end
    end
  end

  test "should do merge as admin" do
    forum = FactoryGirl.create(:cf_write_forum)
    tag = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    tag1 = FactoryGirl.create(:cf_tag, forum_id: forum.forum_id)
    usr = FactoryGirl.create(:cf_user, admin: true)

    sign_in usr

    assert_difference 'CfTag.count', -1 do
      assert_nothing_raised do
        post :do_merge, curr_forum: forum.slug, id: tag.slug, merge_tag: tag1.tag_id
        assert_redirected_to tag_url(forum.slug, tag1)
      end
    end

    tag1.reload
    assert_equal tag.tag_name, tag1.synonyms.first.synonym
  end
end

# eof
