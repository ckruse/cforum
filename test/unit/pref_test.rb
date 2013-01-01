# -*- coding: utf-8 -*-

require 'test_helper'
require 'test_parser_helper'

class PrefTest < ActiveSupport::TestCase
  def setup
    @object = MockObject.new
  end

  test "should generate output for url tag" do
    t = FactoryGirl.create(:cf_thread, tid: 1)
    m = FactoryGirl.create(:cf_message, mid: 1, thread: t, forum: t.forum)

    p = @object.cf_message_url(t, m)
    assert_equal "<a href=\"" + @object.encode_entities(p) + "\">" + @object.encode_entities(p) + "</a>", @object.message_to_html("[pref t=1 m=1][/pref]")
    assert_equal "<a href=\"" + @object.encode_entities(p) + "\">title</a>", @object.message_to_html("[pref t=1 m=1]title[/pref]")

    assert_equal "[url]" + p + "[/url]", @object.message_to_txt("[pref t=1 m=1][/pref]")
    assert_equal "[url=" + p + "]title[/url]", @object.message_to_txt("[pref t=1 m=1]title[/pref]")
  end

  test "should not generate output for invalid tag" do
    assert_equal "[pref][/pref]", @object.message_to_html("[pref][/pref]")
    assert_equal "[pref]heise[/pref]", @object.message_to_html("[pref]heise[/pref]")
    assert_equal "[pref t=10 m=100]Heise[/pref]", @object.message_to_html("[pref t=10 m=100]Heise[/pref]")

    assert_equal "[pref][/pref]", @object.message_to_txt("[pref][/pref]")
    assert_equal "[pref]heise[/pref]", @object.message_to_txt("[pref]heise[/pref]")
    assert_equal "[pref t=10 m=100]Heise[/pref]", @object.message_to_txt("[pref t=10 m=100]Heise[/pref]")
  end

end

# eof
