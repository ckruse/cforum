# -*- coding: utf-8 -*-

require 'test_helper'
require 'test_parser_helper'

class CfForumTest < ActiveSupport::TestCase
  def setup
    @object = MockObject.new
  end

  ##
  ## message_to_html
  ##

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

  test "message_to_html: should handle multiple spaces" do
    assert_equal "&nbsp;&nbsp;&nbsp;&nbsp;", @object.message_to_html("    ")
    assert_equal "blub&nbsp;&nbsp;&nbsp;&nbsp;blub", @object.message_to_html("blub    blub")
    assert_equal "blub blub", @object.message_to_html("blub blub")
  end

  test "message_to_html: invalid tag should not be touched" do
    assert_equal "[code]lalelu", @object.message_to_html("[code]lalelu")
  end

  test "message_to_html: invalid tag closing should not be touched" do
    assert_equal "[code]lalelu[/", @object.message_to_html("[code]lalelu[/")
  end

  test "message_to_html: correct tag should be converted" do
    assert_equal "<code>lalelu</code>", @object.message_to_html("[code]lalelu[/code]")
  end

  test "message_to_html: invalid nested tags should not be touched" do
    assert_equal "<code>lale[url=http://heise.de/]lu[/url</code>", @object.message_to_html("[code]lale[url=http://heise.de/]lu[/url[/code]")
  end

  test "message_to_html: invalid tag with missing ] should not be touched" do
    assert_equal "[code lang=html just a test", @object.message_to_html("[code lang=html just a test")
  end

  test "message_to_html: unknown tag should not be touched" do
    assert_equal "[blub]lwefwef[/blub]", @object.message_to_html("[blub]lwefwef[/blub]")
  end

  test "message_to_html: nested tags should work" do
    assert_equal "<code>lale<a href=\"http://heise.de/\">lu</a></code>", @object.message_to_html("[code]lale[url=http://heise.de/]lu[/url][/code]")
  end

  test "message_to_html: tag with arguments should work" do
    assert_equal "<code title=\"html\"><span class=\"tag\">&lt;html&gt;</span></code>", @object.message_to_html("[code lang=html]<html>[/code]")
  end


  ##
  ## message_to_txt
  ##

  test "message_to_txt: should parse empty" do
    assert_equal "", @object.message_to_txt("")
  end

  test "message_to_txt: should parse line endings" do
    assert_equal "Luke, use the force!\n", @object.message_to_txt("Luke, use the force!\n")
  end

  test "message_to_txt: should convert entities" do
    assert_equal "&<>\"", @object.message_to_txt("&<>\"")
  end

  test "message_to_txt: should be able to handle quotes" do
    assert_equal "> Just a\n> Test\n> > with\n> > > multiple\n> > > > quotes", @object.message_to_txt("\u{ECF0}Just a\n\u{ECF0}Test\n\u{ECF0}\u{ECF0}with\n\u{ECF0}\u{ECF0}\u{ECF0}multiple\n\u{ECF0}\u{ECF0}\u{ECF0}\u{ECF0}quotes")
  end

  test "message_to_txt: should be able to handle signature" do
    assert_equal "\n-- \nblub", @object.message_to_txt("\n-- \nblub")
    assert_equal "blub\n-- \nblub", @object.message_to_txt("blub\n-- \nblub")
  end

  test "message_to_txt: should handle multiple spaces" do
    assert_equal "    ", @object.message_to_txt("    ")
    assert_equal "blub    blub", @object.message_to_txt("blub    blub")
    assert_equal "blub blub", @object.message_to_txt("blub blub")
  end

  test "message_to_txt: invalid tag should not be touched" do
    assert_equal "[code]lalelu", @object.message_to_txt("[code]lalelu")
  end

  test "message_to_txt: invalid tag closing should not be touched" do
    assert_equal "[code]lalelu[/", @object.message_to_txt("[code]lalelu[/")
  end

  test "message_to_txt: correct tag should not be touched" do
    assert_equal "[code]lalelu[/code]", @object.message_to_txt("[code]lalelu[/code]")
  end

  test "message_to_txt: invalid nested tags should not be touched" do
    assert_equal "[code]lale[url=http://heise.de/]lu[/url[/code]", @object.message_to_txt("[code]lale[url=http://heise.de/]lu[/url[/code]")
  end

  test "message_to_txt: invalid tag with missing ] should not be touched" do
    assert_equal "[code lang=html just a test", @object.message_to_txt("[code lang=html just a test")
  end

  test "message_to_txt: unknown tag should not be touched" do
    assert_equal "[blub]lwefwef[/blub]", @object.message_to_txt("[blub]lwefwef[/blub]")
  end

  test "message_to_html: nested tags should not be touched" do
    assert_equal "[code]lale[url=http://heise.de/]lu[/url][/code]", @object.message_to_txt("[code]lale[url=http://heise.de/]lu[/url][/code]")
  end

  test "message_to_txt: tag with arguments should work" do
    assert_equal "[code lang=html]<html>[/code]", @object.message_to_txt("[code lang=html]<html>[/code]")
  end

  ##
  ## quote_content
  ##

  test "quote_content should work" do
    assert_equal "> [blah]\n> blub\n> > blah", @object.quote_content("[blah]\nblub\n> blah", '> ')
  end

  test "quote_content should remove signature" do
    assert_equal "> [blah]\n> blub\n> > blah", @object.quote_content("[blah]\nblub\n> blah\n-- \nsig", '> ')
  end

  test "quote_content should not remove signature" do
    class << @object
      def uconf(nam, def_val)
        'yes'
      end
    end

    assert_equal "> [blah]\n> blub\n> > blah\n> -- \n> sig", @object.quote_content("[blah]\nblub\n> blah\n-- \nsig", '> ')
  end

  ##
  ## content_to_internal
  ##

  test "content_to_internal should normalize line endings" do
    assert_equal "blah\nblub\nblah\n", @object.content_to_internal("blah\nblub\r\nblah\r\n", '> ')
  end

  test "content_to_internal should normalize quoting" do
    assert_equal "\u{ECF0}bl> ah\n\u{ECF0}blub\n\n\u{ECF0}\u{ECF0}blah", @object.content_to_internal("> bl> ah\n> blub\n\n> > blah", '> ')
    assert_equal "\u{ECF0}blah\n\u{ECF0}blub\n\n\u{ECF0}\u{ECF0}blah", @object.content_to_internal("| blah\n| blub\n\n| | blah", '| ')
    assert_equal "> blah\n> blub\n\n> > blah", @object.content_to_internal("> blah\n> blub\n\n> > blah", '| ')
  end

end


# eof
