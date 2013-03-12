# -*- coding: utf-8 -*-

require 'test_helper'

class CfTagSynonymTest < ActiveSupport::TestCase
  test "validations" do
    tag = FactoryGirl.create(:cf_tag)
    tag_syn = CfTagSynonym.new

    assert !tag_syn.save

    tag_syn.tag_id = tag.tag_id
    assert !tag_syn.save

    tag_syn.synonym = 'lulu'
    assert !tag_syn.save

    tag_syn.forum_id = tag.forum_id
    assert tag_syn.save
  end

  test "tag relation" do
    tag = FactoryGirl.create(:cf_tag)
    tag_syn = CfTagSynonym.create!(tag_id: tag.tag_id, forum_id: tag.forum_id, synonym: 'lulu')

    st = CfTagSynonym.find tag_syn.tag_synonym_id
    assert_not_nil st
    assert_not_nil st.tag
    assert_equal tag.tag_id, st.tag_id
  end

  test "forum relation" do
    tag = FactoryGirl.create(:cf_tag)
    tag_syn = CfTagSynonym.create!(tag_id: tag.tag_id, forum_id: tag.forum_id, synonym: 'lulu')

    st = CfTagSynonym.find tag_syn.tag_synonym_id
    assert_not_nil st
    assert_not_nil st.forum
    assert_equal tag.forum_id, st.forum_id
  end
end


# eof
