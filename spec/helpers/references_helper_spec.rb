require 'rails_helper'

RSpec.describe ReferencesHelper do
  it 'returns a list of links from a HTML document' do
    html = <<~HTML
      <a href="lulu"></a>
      <a href=""></a>
      <a href="http://example.org"></a>
      <a href=""></a>
    HTML

    expect(find_links(html)).to eq ['lulu', 'http://example.org']
  end

  it 'returns a list of links specific to a URL' do
    html = <<~HTML
      <a href="http://example.org/all/2015/jan/1/blub/1234"></a>
      <a href="http://example.org/all/2015/jan/1/blub/1235"></a>
      <a href="https://example.org/all/2015/jan/1/blub/1234"></a>
      <a href="https://example.org/all/2015/jan/1/blub/1235"></a>
      <a href="http://wwwtech.de/all/2015/jan/1/blub/1234"></a>
      <a href="http://wwwtech.de/all/2015/jan/1/blub/1235"></a>
      <a href="https://wwwtech.de/all/2015/jan/1/blub/1234"></a>
      <a href="https://wwwtech.de/all/2015/jan/1/blub/1235"></a>
    HTML

    expect(find_references(html, 'example.org')).to eq ['http://example.org/all/2015/jan/1/blub/1234',
                                                        'http://example.org/all/2015/jan/1/blub/1235',
                                                        'https://example.org/all/2015/jan/1/blub/1234',
                                                        'https://example.org/all/2015/jan/1/blub/1235']
  end

  it 'returns only posting links' do
    html = <<~HTML
      <a href="http://example.org/all/2015/jan/1/blub/1234"></a>
      <a href="http://example.org/all/2015/jan/1/blub/1235"></a>
      <a href="https://example.org/all/2015/jan/1/blub/1234"></a>
      <a href="https://example.org/all/2015/jan/1/blub/1235"></a>
      <a href="https://example.org/all/2015/jan/1/blub/1235#m1235"></a>
      <a href="https://example.org/all/2015/jan/1/blub/1235/interesting"></a>
      <a href="http://example.org/blah"></a>
      <a href="http://example.org/blub/blah/blub"></a>
      <a href="https://example.org/blub"></a>
      <a href="https://example.org/blub/blah/blub"></a>
    HTML

    expect(find_references(html, 'example.org')).to eq ['http://example.org/all/2015/jan/1/blub/1234',
                                                        'http://example.org/all/2015/jan/1/blub/1235',
                                                        'https://example.org/all/2015/jan/1/blub/1234',
                                                        'https://example.org/all/2015/jan/1/blub/1235',
                                                        'https://example.org/all/2015/jan/1/blub/1235#m1235']
  end

  it 'returns shortened URLs as well' do
    html = <<~HTML
      <a href="http://example.org/m1234"></a>
    HTML

    expect(find_references(html, 'example.org')).to eq ['http://example.org/m1234']
  end

  it 'returns correct mid from normal link' do
    expect(mid_from_uri('http://example.org/all/2015/jan/1/blub/1234')).to eq 1234
  end

  it 'returns correct mid from shortened link' do
    expect(mid_from_uri('http://example.org/m1234')).to eq 1234
  end
end

# eof
