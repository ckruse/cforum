require 'rails_helper'

RSpec.describe SuspiciousHelper do
  def current_user
    nil
  end
  include ApplicationHelper

  it 'returns true for a name containing non-latin1 characters' do
    name = 'Luke▲Skywalker…'
    expect(name_suspicious?(name)).to be(true)
  end
  it 'returns false for a name w/o non-latin1 characters' do
    name = 'Luke Skywalker äöü'
    expect(name_suspicious?(name)).to be(false)
  end

  it 'checks a number for messages for suspiciousness' do
    messages = [create(:message),
                create(:message, author: 'Luke▲Skywalker…'),
                create(:message, author: 'Luke Skywalker äüöß')]

    check_messages_for_suspiciousness(messages)

    expect(messages.first.attribs['classes']).to_not include('suspicious')
    expect(messages.second.attribs['classes']).to include('suspicious')
    expect(messages.third.attribs['classes']).to_not include('suspicious')
  end

  it 'checks all messages of a thread list for suspicious nicks' do
    messages = [create(:message),
                create(:message, author: 'Luke▲Skywalker…'),
                create(:message, author: 'Luke Skywalker äüöß')]

    threads = messages.map(&:thread)
    messages = []
    threads.each do |thread|
      thread.gen_tree
      messages << thread.sorted_messages.first
    end

    check_threads_for_suspiciousness(threads)

    expect(messages.first.attribs['classes']).to_not include('suspicious')
    expect(messages.second.attribs['classes']).to include('suspicious')
    expect(messages.third.attribs['classes']).to_not include('suspicious')
  end
end

# eof
