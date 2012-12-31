# -*- coding: utf-8 -*-

require 'test_helper'
require 'test_parser_helper'

class CfForumTest < ActiveSupport::TestCase
  def setup
    @object = MockObject.new
  end

  test "message_to_html: should parse empty" do
    assert_equal "", @object.message_to_html("")
  end

  test "message_to_html: should parse line endings" do
    assert_equal "Luke, use the force!<br>", @object.message_to_html("Luke, use the force!\n")
  end

  test "message_to_html: should convert entities" do
    assert_equal "&amp;&lt;&gt;&quot;", @object.message_to_html("&<>\"")
  end

  test "message_to_html: should be able to handle quotes" do
    assert_equal '<span class="q">&gt; Just a<br>&gt; Test<br><span class="q">&gt; &gt; with<br><span class="q">&gt; &gt; &gt; multiple<br><span class="q">&gt; &gt; &gt; &gt; quotes</span></span></span></span>', @object.message_to_html("\u{ECF0}Just a\n\u{ECF0}Test\n\u{ECF0}\u{ECF0}with\n\u{ECF0}\u{ECF0}\u{ECF0}multiple\n\u{ECF0}\u{ECF0}\u{ECF0}\u{ECF0}quotes")
  end

  test "message_to_html: should be able to handle signature" do
    assert_equal "<span class=\"signature\"><br>-- <br>blub</span>", @object.message_to_html("\n-- \nblub")
assert_equal "blub<span class=\"signature\"><br>-- <br>blub</span>", @object.message_to_html("blub\n-- \nblub")
  end

  test "should handle multiple spaces" do
    assert_equal "&nbsp;&nbsp;&nbsp;&nbsp;", @object.message_to_html("    ")
    assert_equal "blub&nbsp;&nbsp;&nbsp;&nbsp;blub", @object.message_to_html("blub    blub")
    assert_equal "blub blub", @object.message_to_html("blub blub")
  end

end


# eof
