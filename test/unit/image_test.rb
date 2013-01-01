# -*- coding: utf-8 -*-

require 'test_helper'
require 'test_parser_helper'

class ImageTest < ActiveSupport::TestCase
  def setup
    @object = MockObject.new
  end

  test "should generate output for image tag" do
    assert_equal "<img src=\"http://heise.de/blah.gif\" alt=\"http://heise.de/blah.gif\" title=\"http://heise.de/blah.gif\">", @object.message_to_html("[img]http://heise.de/blah.gif[/img]")
    assert_equal "<img src=\"http://heise.de/blah.gif\" alt=\"Heise\" title=\"Heise\">", @object.message_to_html("[img=http://heise.de/blah.gif]Heise[/img]")

    assert_equal "[img]http://heise.de/blah.gif[/img]", @object.message_to_txt("[img]http://heise.de/blah.gif[/img]")
    assert_equal "[url=http://heise.de/blah.gif]Heise[/url]", @object.message_to_txt("[url=http://heise.de/blah.gif]Heise[/url]")
  end

  test "should not generate html for invalid link" do
    assert_equal "[img][/img]", @object.message_to_html("[img][/img]")
    assert_equal "[img]heise[/img]", @object.message_to_html("[img]heise[/img]")
    assert_equal "[img=wefwef]Heise[/img]", @object.message_to_html("[img=wefwef]Heise[/img]")

    assert_equal "[img][/img]", @object.message_to_txt("[img][/img]")
    assert_equal "[img]heise[/img]", @object.message_to_txt("[img]heise[/img]")
    assert_equal "[img=wefwef]Heise[/img]", @object.message_to_txt("[img=wefwef]Heise[/img]")
  end

end

# eof
