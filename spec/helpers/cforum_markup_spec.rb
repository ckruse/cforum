# rubocop:disable Metrics/LineLength

require 'rails_helper'

RSpec.describe CforumMarkup do
  describe 'converts newlines' do
    it 'replaces <br/> by newlines with space' do
      expect(cforum2markdown('<br/>')).to eq("  \n")
      expect(cforum2markdown('<br />')).to eq("  \n")
      expect(cforum2markdown('<br />' * 3)).to eq("\n" * 3)
    end
  end

  describe 'converts non-breaking spaces' do
    it 'replaces &#160; by a non-breaking space' do
      expect(cforum2markdown('&#160;')).to eq(' ')
      expect(cforum2markdown('&#160;' * 3)).to eq(' ' * 3)
    end
  end

  describe 'converts U007F to a cite' do
    it 'converts U007F at the beginning of a line' do
      expect(cforum2markdown("\u007f")).to eq('> ')
      expect(cforum2markdown("wfwefwef<br />\u007f")).to eq("wfwefwef  \n> ")
      expect(cforum2markdown("wfwefwef<br />\u007fwefwefwef")).to eq("wfwefwef  \n> wefwefwef")
    end

    it 'converts U007F on other places than beginning of line' do
      expect(cforum2markdown("wefwef\u007f")).to eq('wefwef> ')
    end
  end

  describe 'converts images' do
    it 'converts [image:url]' do
      expect(cforum2markdown('[image:/foo/bar]')).to eq('![](/foo/bar)')
      expect(cforum2markdown('[image:bar]')).to eq('![](bar)')
      expect(cforum2markdown('[image:http://example.org/foo/bar]')).to eq('![](http://example.org/foo/bar)')
    end

    it 'converts [image:url@alt=]' do
      expect(cforum2markdown('[image:/foo/bar@alt=baz]')).to eq('![baz](/foo/bar)')
      expect(cforum2markdown('[image:bar@alt=baz]')).to eq('![baz](bar)')
      expect(cforum2markdown('[image:http://example.org/foo/bar@alt=baz]')).to eq('![baz](http://example.org/foo/bar)')
    end

    it 'converts special form: <img>' do
      expect(cforum2markdown('<img src="/foo/bar">')).to eq('![](/foo/bar)')
      expect(cforum2markdown('<img src="bar">')).to eq('![](bar)')
      expect(cforum2markdown('<img src="http://example.org/foo/bar">')).to eq('![](http://example.org/foo/bar)')
    end

    it 'converts special form: <img> with alt' do
      expect(cforum2markdown('<img src="/foo/bar" alt="foo">')).to eq('![foo](/foo/bar)')
      expect(cforum2markdown('<img alt="baz" src="bar">')).to eq('![baz](bar)')
      expect(cforum2markdown('<img alt="moo" src="http://example.org/foo/bar">')).to eq('![moo](http://example.org/foo/bar)')
    end
  end

  describe 'converts links' do
    it 'converts [link:url]' do
      expect(cforum2markdown('[link:/foo/bar]')).to eq('[/foo/bar](/foo/bar)')
      expect(cforum2markdown('[link:bar]')).to eq('[bar](bar)')
      expect(cforum2markdown('[link:http://example.org/foo/bar]')).to eq('[http://example.org/foo/bar](http://example.org/foo/bar)')
    end

    it 'converts [link:url@title=]' do
      expect(cforum2markdown('[link:/foo/bar@title=baz]')).to eq('[baz](/foo/bar)')
      expect(cforum2markdown('[link:bar@title=baz]')).to eq('[baz](bar)')
      expect(cforum2markdown('[link:http://example.org/foo/bar@title=baz]')).to eq('[baz](http://example.org/foo/bar)')
    end
  end

  describe 'converts pref' do
    it 'converts [pref:]' do
      expect(cforum2markdown('[pref:t=1;m=1]')).to eq('[?t=1&m=1](/?t=1&m=1)')
      expect(cforum2markdown('[pref:t=1&amp;m=1]')).to eq('[?t=1&m=1](/?t=1&m=1)')
    end

    it 'converts [pref:@title=]' do
      expect(cforum2markdown('[pref:t=1;m=1@title=foo]')).to eq('[foo](/?t=1&m=1)')
      expect(cforum2markdown('[pref:t=1&amp;m=1@title=foo]')).to eq('[foo](/?t=1&m=1)')
    end
  end

  describe 'converts ref' do
    it 'converts ref:self8x and ref:slef8x as well as with @title' do
      %w[self8 self81 self811 self812 sel811 sef811 slef812].each do |ref|
        expect(cforum2markdown("[ref:#{ref};foo]")).to eq('[http://de.selfhtml.org/foo](http://de.selfhtml.org/foo)')
        expect(cforum2markdown("[ref:#{ref};foo@title=bar]")).to eq('[bar](http://de.selfhtml.org/foo)')
      end
    end

    it 'converts self7 and self7@title' do
      expect(cforum2markdown('[ref:self7;foo]')).to eq('[http://aktuell.de.selfhtml.org/archiv/doku/7.0/foo](http://aktuell.de.selfhtml.org/archiv/doku/7.0/foo)')
      expect(cforum2markdown('[ref:self7;foo@title=bar]')).to eq('[bar](http://aktuell.de.selfhtml.org/archiv/doku/7.0/foo)')
    end

    it 'converts zitat and zitat@title' do
      expect(cforum2markdown('[ref:zitat;foo]')).to eq('[/cites/old/foo](/cites/old/foo)')
      expect(cforum2markdown('[ref:zitat;foo@title=bar]')).to eq('[bar](/cites/old/foo)')
    end
  end

  describe 'converts latex' do
    it 'converts latex block' do
      expect(cforum2markdown("\n[latex]foo bar\nmoo[/latex]\n")).to eq("\n$$foo bar\nmoo$$\n")
    end
    it 'converts latex inline' do
      expect(cforum2markdown('foo [latex]foo bar[/latex]')).to eq('foo $$foo bar$$')
    end
  end

  describe 'converts code' do
    it 'converts block code w/o lang'
    it 'converts block code with lang'
    it 'converts inline code w/o lang'
    it 'converts inline code with lang'
    it 'fixes code in quotes'

    it 'converts conditional comments like in m1308019' do
      content = '[code lang=html]&lt;!--[if !(IE 6)]&gt;&lt;!--&gt;&lt;p&gt;nicht für IE 6&lt;/p&gt;&lt;!--&lt;![endif]--&gt;[/code]'
      expect(cforum2markdown(content)).to eq('`<!--[if !(IE 6)]><!--><p>nicht für IE 6</p><!--<![endif]-->`{:.language-html}')
    end

    it 'converts code in code correctly as in m1627963' do
      content = '[code lang=html]&lt;?php [code lang=php]if (!empty($row[12])):[/code] ?&gt;<br />  &lt;div id=&quot;&lt;?php [code lang=php]echo $row[8];[/code] ?&gt;d1_nebenzeilen&quot;&gt;&lt;br&gt;&lt;?php [code lang=php]echo $row[12];[/code] ?&gt;&lt;/div&gt;<br />&lt;?php [code lang=php]endif;[/code] ?&gt;[/code]<br /><br />Was soll das [code lang=html]&lt;br&gt;[/code]'
      expect(cforum2markdown(content)).to eql("\n\n~~~ html\n<?php if (!empty($row[12])): ?>  \n  <div id=\"<?php echo $row[8]; ?>d1_nebenzeilen\"><br><?php echo $row[12]; ?></div>  \n<?php endif; ?>\n\n~~~\n\nWas soll das `<br>`{:.language-html}")
    end

    it 'generates newlines when they are missing at the end of a code block' do
      content = '[code]foo<br />bar<br />baz<br />[/code]bam'
      expect(cforum2markdown(content)).to eql("\n\n~~~\nfoo  \nbar  \nbaz  \n\n~~~\n\nbam")
    end
  end

  describe 'special foo' do
    it 'converts email-style signature' do
      expect(cforum2markdown('<br />-- <br />foo')).to eq("\n-- \nfoo")
    end

    it 'escapes --{2,} in non-code' do
      expect(cforum2markdown('--')).to eq('\\--')
      expect(cforum2markdown('----')).to eq('\\----')
    end

    it 'escapes ^# in non-code' do
      expect(cforum2markdown('#')).to eq('\\#')
      expect(cforum2markdown('foo bar<br />#')).to eq("foo bar\n\\#")
      expect(cforum2markdown('foo bar<br />  #')).to eq("foo bar\n  \\#")
    end

    it 'escapes * in non-code' do
      expect(cforum2markdown('*')).to eq('\\*')
      expect(cforum2markdown('foo bar<br />*')).to eq("foo bar  \n\\*")
      expect(cforum2markdown('foo bar<br />  *')).to eq("foo bar  \n  \\*")
    end

    it 'escapes _ in non-code' do
      expect(cforum2markdown('_')).to eq('\\_')
      expect(cforum2markdown('foo bar<br />_')).to eq("foo bar  \n\\_")
      expect(cforum2markdown('foo bar<br />  _')).to eq("foo bar  \n  \\_")
    end
  end
end
