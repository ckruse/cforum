# -*- coding: utf-8 -*-

require "rails_helper"

RSpec.describe "problematic site is in preview" do
  let(:message) { create(:cf_message, content: "~~~brainfuck
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
~~~") }

  include CForum::Tools

  it "has no problematic site when value is empty" do
    visit cf_message_path(message.thread, message)
    expect(page.find(".posting-content")).to have_css("code.block")
  end
end

# eof
