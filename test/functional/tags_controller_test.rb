# -*- coding: utf-8 -*-

require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  test "should show empty index" do
    forum = FactoryGirl.create(:cf_forum)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_empty assigns(:tags)
  end

  test "should show index" do
    forum = FactoryGirl.create(:cf_forum)
    tag = FactoryGirl.create(:cf_tag, forum: forum)

    get :index, {curr_forum: forum.slug}
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_not_empty assigns(:tags)
  end

  test "should show index with search" do
    forum = FactoryGirl.create(:cf_forum)
    tag = FactoryGirl.create(:cf_tag, forum: forum)

    get :index, {curr_forum: forum.slug, s: tag.tag_name[0..2]}
    assert_response :success
    assert_not_nil assigns(:tags)
    assert_not_empty assigns(:tags)
  end


  test "should not show because does not exist" do
    forum = FactoryGirl.create(:cf_forum)
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
    forum = FactoryGirl.create(:cf_forum)

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

end

# eof
