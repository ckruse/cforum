# -*- coding: utf-8 -*-

require "rails_helper"

RSpec.describe "highlights with different cases" do
  include CForum::Tools

  it "renders to code class=block" do
    messages = []
    messages << create(:cf_message, content: <<HTML
~~~html
<html>
~~~
HTML
                    )

    messages << create(:cf_message, content: <<HTML
~~~HTML
<html>
~~~
HTML
                     )

    messages << create(:cf_message, content: <<HTML
~~~hTmL
<html>
~~~
HTML
                    )

    messages.each do |message|
      visit cf_message_path(message.thread, message)
      expect(page.find(".posting-content code.block")).to have_css("span.nt", text: "<html>")
    end
  end

  it "renders to code class=block in block quotes" do
    messages = []
    messages << create(:cf_message, content: <<HTML
> ~~~html
> <html>
> ~~~
HTML
                    )

    messages << create(:cf_message, content: <<HTML
> ~~~html
> <html>
> ~~~
HTML
                     )

    messages << create(:cf_message, content: <<HTML
> ~~~html
> <html>
> ~~~
HTML
                    )

    messages.each do |message|
      visit cf_message_path(message.thread, message)
      expect(page.find(".posting-content code.block")).to have_css("span.nt", text: "<html>")
    end
  end
end

# eof
