require 'rails_helper'

RSpec.describe MessageVersion, type: :model do
  it 'returns subject and content as diff content' do
    m = MessageVersion.new(subject: 'Foo', content: 'Bar')
    expect(m.diff_content).to eq(m.subject + "\n\n" + m.content)
  end
end
