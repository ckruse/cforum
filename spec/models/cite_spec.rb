require 'rails_helper'

RSpec.describe Cite, type: :model do
  it 'is valid with a cite text' do
    expect(Cite.new(cite: 'Help me, Obi-Wan Kenobi. You\'re my only hope.')).to be_valid
  end

  it 'is invalid w/o a cite text' do
    expect(Cite.new).to be_invalid
  end
end

# eof
