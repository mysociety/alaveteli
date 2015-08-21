# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HighlightHelper do
  include HighlightHelper

  describe '#highlight_and_excerpt' do

    it 'excerpts text and highlights phrases' do
      text = "Quentin Nobble-Boston, Permanent Under-Secretary, Department for Humpadinking"
      phrases = ['humpadinking']
      expected = '...Department for <span class="highlight">Humpadinking</span>'
      expect(highlight_and_excerpt(text, phrases, 15)).to eq(expected)
    end

    it 'excerpts text and highlights matches' do
      text = "Quentin Nobble-Boston, Permanent Under-Secretary, Department for Humpadinking"
      matches = [/\bhumpadink\w*\b/iu]
      expected = '...Department for <span class="highlight">Humpadinking</span>'
      expect(highlight_and_excerpt(text, matches, 15)).to eq(expected)
    end

    context 'multiple matches' do

      it 'highlights multiple matches' do
        text = <<-EOF
Quentin Nobble-Boston, Permanent Under-Secretary, Department for Humpadinking
decided to visit Humpadink so that he could be with the Humpadinks
EOF

        expected = <<-EOF
Quentin Nobble-Boston, Permanent Under-Secretary, Department for <span class="highlight">Humpadinking</span>
decided to visit <span class="highlight">Humpadink</span> so that he could be with the <span class="highlight">Humpadinks</span>
EOF
        text.chomp!
        expected.chomp!
        matches = [/\b(humpadink\w*)\b/iu]
        expect(highlight_and_excerpt(text, matches, 1000)).to eq(expected)
      end

      it 'bases the split on the first match' do
        text = "Quentin Nobble-Boston, Permanent Under-Secretary," \
          "Department for Humpadinking decided to visit Humpadink" \
          "so that he could be with the Humpadinks"

        expected = "...Department for <span class=\"highlight\">" \
          "Humpadinking</span> decided to vis..."

        matches = [/\b(humpadink\w*)\b/iu]
        expect(highlight_and_excerpt(text, matches, 15)).to eq(expected)
      end

    end

  end

  describe '#highlight_matches' do

    it 'highlights' do
      assert_equal(
        "This is a <mark>beautiful</mark> morning",
        highlight_matches("This is a beautiful morning", "beautiful")
      )

      assert_equal(
        "This is a <mark>beautiful</mark> morning, but also a <mark>beautiful</mark> day",
        highlight_matches("This is a beautiful morning, but also a beautiful day", "beautiful")
      )

      assert_equal(
        "This is a <b>beautiful</b> morning, but also a <b>beautiful</b> day",
        highlight_matches("This is a beautiful morning, but also a beautiful day", "beautiful", :highlighter => '<b>\1</b>')
      )

      assert_equal(
        "This text is not changed because we supplied an empty phrase",
        highlight_matches("This text is not changed because we supplied an empty phrase", nil)
      )

      assert_equal '   ', highlight_matches('   ', 'blank text is returned verbatim')
    end

    it 'sanitizes input' do
      assert_equal(
        "This is a <mark>beautiful</mark> morning",
        highlight_matches("This is a beautiful morning<script>code!</script>", "beautiful")
      )
    end

    it 'doesnt sanitize when the sanitize option is false' do
      assert_equal(
        "This is a <mark>beautiful</mark> morning<script>code!</script>",
        highlight_matches("This is a beautiful morning<script>code!</script>", "beautiful", :sanitize => false)
      )
    end

    it 'highlights using regexp' do
      assert_equal(
        "This is a <mark>beautiful!</mark> morning",
        highlight_matches("This is a beautiful! morning", "beautiful!")
      )

      assert_equal(
        "This is a <mark>beautiful! morning</mark>",
        highlight_matches("This is a beautiful! morning", "beautiful! morning")
      )

      assert_equal(
        "This is a <mark>beautiful? morning</mark>",
        highlight_matches("This is a beautiful? morning", "beautiful? morning")
      )
    end

    it 'accepts regex' do
      assert_equal("This day was challenging for judge <mark>Allen</mark> and his colleagues.",
                   highlight_matches("This day was challenging for judge Allen and his colleagues.", /\ballen\b/i))
    end

    it 'highlights multiple phrases in one pass' do
      assert_equal %(<em>wow</em> <em>em</em>), highlight_matches('wow em', %w(wow em), :highlighter => '<em>\1</em>')
    end

    it 'highlights with html' do
      assert_equal(
        "<p>This is a <mark>beautiful</mark> morning, but also a <mark>beautiful</mark> day</p>",
        highlight_matches("<p>This is a beautiful morning, but also a beautiful day</p>", "beautiful")
      )
      assert_equal(
        "<p>This is a <em><mark>beautiful</mark></em> morning, but also a <mark>beautiful</mark> day</p>",
        highlight_matches("<p>This is a <em>beautiful</em> morning, but also a beautiful day</p>", "beautiful")
      )
      assert_equal(
        "<p>This is a <em class=\"error\"><mark>beautiful</mark></em> morning, but also a <mark>beautiful</mark> <span class=\"last\">day</span></p>",
        highlight_matches("<p>This is a <em class=\"error\">beautiful</em> morning, but also a beautiful <span class=\"last\">day</span></p>", "beautiful")
      )
      assert_equal(
        "<p class=\"beautiful\">This is a <mark>beautiful</mark> morning, but also a <mark>beautiful</mark> day</p>",
        highlight_matches("<p class=\"beautiful\">This is a beautiful morning, but also a beautiful day</p>", "beautiful")
      )
      assert_equal(
        "<p>This is a <mark>beautiful</mark> <a href=\"http://example.com/beautiful#top?what=beautiful%20morning&amp;when=now+then\">morning</a>, but also a <mark>beautiful</mark> day</p>",
        highlight_matches("<p>This is a beautiful <a href=\"http://example.com/beautiful\#top?what=beautiful%20morning&when=now+then\">morning</a>, but also a beautiful day</p>", "beautiful")
      )
      assert_equal(
        "<div>abc <b>div</b></div>",
        highlight_matches("<div>abc div</div>", "div", :highlighter => '<b>\1</b>')
      )
    end

    it 'doesnt modify the options hash' do
      options = { :highlighter => '<b>\1</b>', :sanitize => false }
      passed_options = options.dup
      highlight_matches("<div>abc div</div>", "div", passed_options)
      assert_equal options, passed_options
    end

    it 'highlights with a block' do
      assert_equal(
        "<b>one</b> <b>two</b> <b>three</b>",
        highlight_matches("one two three", ["one", "two", "three"]) { |word| "<b>#{word}</b>" }
      )
    end

  end

  describe '#excerpt' do

    it 'excerpts' do
      assert_equal("...is a beautiful morn...", excerpt("This is a beautiful morning", "beautiful", :radius => 5))
      assert_equal("This is a...", excerpt("This is a beautiful morning", "this", :radius => 5))
      assert_equal("...iful morning", excerpt("This is a beautiful morning", "morning", :radius => 5))
      assert_nil excerpt("This is a beautiful morning", "day")
    end

    it 'is not html safe' do
      assert !excerpt('This is a beautiful! morning', 'beautiful', :radius => 5).html_safe?
    end

    it 'excerpts borderline cases' do
      assert_equal("", excerpt("", "", :radius => 0))
      assert_equal("a", excerpt("a", "a", :radius => 0))
      assert_equal("...b...", excerpt("abc", "b", :radius => 0))
      assert_equal("abc", excerpt("abc", "b", :radius => 1))
      assert_equal("abc...", excerpt("abcd", "b", :radius => 1))
      assert_equal("...abc", excerpt("zabc", "b", :radius => 1))
      assert_equal("...abc...", excerpt("zabcd", "b", :radius => 1))
      assert_equal("zabcd", excerpt("zabcd", "b", :radius => 2))

      # excerpt strips the resulting string before ap-/prepending excerpt_string.
      # whether this behavior is meaningful when excerpt_string is not to be
      # appended is questionable.
      assert_equal("zabcd", excerpt("  zabcd  ", "b", :radius => 4))
      assert_equal("...abc...", excerpt("z  abc  d", "b", :radius => 1))
    end

    it 'excerpts with regex' do
      assert_equal('...is a beautiful! mor...', excerpt('This is a beautiful! morning', 'beautiful', :radius => 5))
      assert_equal('...is a beautiful? mor...', excerpt('This is a beautiful? morning', 'beautiful', :radius => 5))
      assert_equal('...is a beautiful? mor...', excerpt('This is a beautiful? morning', /\bbeau\w*\b/i, :radius => 5))
      assert_equal('...is a beautiful? mor...', excerpt('This is a beautiful? morning', /\b(beau\w*)\b/i, :radius => 5))
      assert_equal("...udge Allen and...", excerpt("This day was challenging for judge Allen and his colleagues.", /\ballen\b/i, :radius => 5))
      assert_equal("...judge Allen and...", excerpt("This day was challenging for judge Allen and his colleagues.", /\ballen\b/i, :radius => 1, :separator => ' '))
      assert_equal("...was challenging for...", excerpt("This day was challenging for judge Allen and his colleagues.", /\b(\w*allen\w*)\b/i, :radius => 5))
    end

    it 'excerpts with omission' do
      assert_equal("[...]is a beautiful morn[...]", excerpt("This is a beautiful morning", "beautiful", :omission => "[...]",:radius => 5))
      assert_equal(
        "This is the ultimate supercalifragilisticexpialidoceous very looooooooooooooooooong looooooooooooong beautiful morning with amazing sunshine and awesome tempera[...]",
        excerpt("This is the ultimate supercalifragilisticexpialidoceous very looooooooooooooooooong looooooooooooong beautiful morning with amazing sunshine and awesome temperatures. So what are you gonna do about it?", "very",
                :omission => "[...]")
      )
    end

    it 'excerpts with utf8' do
      if RUBY_VERSION.to_f >= 1.9
        assert_equal("...\357\254\203ciency could not be...".force_encoding(Encoding::UTF_8), excerpt("That's why e\357\254\203ciency could not be helped".force_encoding(Encoding::UTF_8), 'could', :radius => 8))
      else
        assert_equal("...\357\254\203ciency could not be...", excerpt("That's why e\357\254\203ciency could not be helped", 'could', :radius => 8))
      end
    end

    it 'doesnt modify the options hash' do
      options = { :omission => "[...]",:radius => 5 }
      passed_options = options.dup
      excerpt("This is a beautiful morning", "beautiful", passed_options)
      assert_equal options, passed_options
    end

    it 'excerpts with separator' do
      options = { :separator => ' ', :radius => 1 }
      assert_equal('...a very beautiful...', excerpt('This is a very beautiful morning', 'very', options))
      assert_equal('This is...', excerpt('This is a very beautiful morning', 'this', options))
      assert_equal('...beautiful morning', excerpt('This is a very beautiful morning', 'morning', options))

      options = { :separator => "\n", :radius => 0 }
      assert_equal("...very long...", excerpt("my very\nvery\nvery long\nstring", 'long', options))

      options = { :separator => "\n", :radius => 1 }
      assert_equal("...very\nvery long\nstring", excerpt("my very\nvery\nvery long\nstring", 'long', options))

      assert_equal excerpt('This is a beautiful morning', 'a'),
        excerpt('This is a beautiful morning', 'a', :separator => nil)
    end

  end

end
