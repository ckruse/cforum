# -*- coding: utf-8 -*-

require 'test_helper'
require 'test_parser_helper'

class LinkTest < ActiveSupport::TestCase
  def setup
    @object = MockObject.new
  end

  test "should generate output for url tag" do
    assert_equal "<a href=\"http://heise.de/\">http://heise.de/</a>", @object.message_to_html("[url]http://heise.de/[/url]")
    assert_equal "<a href=\"http://heise.de/\">Heise</a>", @object.message_to_html("[url=http://heise.de/]Heise[/url]")

    assert_equal "[url]http://heise.de/[/url]", @object.message_to_txt("[url]http://heise.de/[/url]")
    assert_equal "[url=http://heise.de/]Heise[/url]", @object.message_to_txt("[url=http://heise.de/]Heise[/url]")
  end

  test "should not generate html for invalid link" do
    assert_equal "[url][/url]", @object.message_to_html("[url][/url]")
    assert_equal "[url]heise[/url]", @object.message_to_html("[url]heise[/url]")
    assert_equal "[url=wefwef]Heise[/url]", @object.message_to_html("[url=wefwef]Heise[/url]")

    assert_equal "[url][/url]", @object.message_to_txt("[url][/url]")
    assert_equal "[url]heise[/url]", @object.message_to_txt("[url]heise[/url]")
    assert_equal "[url=wefwef]Heise[/url]", @object.message_to_txt("[url=wefwef]Heise[/url]")
  end

end

# eof
