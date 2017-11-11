require 'rails_helper'

RSpec.describe 'problematic site is in preview' do
  let(:message) do
    create(:message, content: "~~~brainfuck
++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++.
~~~")
  end

  include CForum::Tools

  it 'renders to code class=block' do
    visit message_path(message.thread, message)
    expect(page.find('.thread-message:not(.preview) .posting-content'))
      .to have_css('code.block')
  end
end

# eof
