# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AlaveteliGetText::FuzzyCleaner do

  describe '#clean_po' do

    it 'removes the fuzzy marker and msgstr from a single-line msgstr' do
      input = <<-EOF.strip_heredoc
      msgid "Some msgid"
      msgstr "Translated msgstr"

      #, fuzzy
      msgid "Fuzzy msgid"
      msgstr "Fuzzy translation"

      msgid "Another msgid"
      msgstr "Another translated msgstr"
      EOF

      expected = <<-EOF.strip_heredoc
      msgid "Some msgid"
      msgstr "Translated msgstr"

      msgid "Fuzzy msgid"
      msgstr ""

      msgid "Another msgid"
      msgstr "Another translated msgstr"
      EOF

      expect(subject.clean_po(input)).to eq(expected)
    end

    it 'removes the fuzzy marker and msgstr from a multi-line msgstr' do
      input = <<-EOF.strip_heredoc
      msgid "Some msgid"
      msgstr "Translated msgstr"

      #, fuzzy
      msgid "Multi-line fuzzy"
      msgstr ""
      "Fuzzy translation…"
      "…over several "
      "lines"

      msgid "Another msgid"
      msgstr "Another translated msgstr"
      EOF

      expected = <<-EOF.strip_heredoc
      msgid "Some msgid"
      msgstr "Translated msgstr"

      msgid "Multi-line fuzzy"
      msgstr ""

      msgid "Another msgid"
      msgstr "Another translated msgstr"
      EOF

      expect(subject.clean_po(input)).to eq(expected)
    end

    it 'removes the fuzzy marker and msgstrs from a plural msgstr' do
      input = <<-EOF.strip_heredoc
      msgid "Some msgid"
      msgstr "Translated msgstr"

      #, fuzzy
      msgid "Fuzzy msgid"
      msgid_plural "Plural fuzzy"
      msgstr[0] "Fuzzy translation"
      msgstr[1] "Plural translation"
      msgstr[2] "Further plural"

      msgid "Another msgid"
      msgstr "Another translated msgstr"
      EOF

      expected = <<-EOF.strip_heredoc
      msgid "Some msgid"
      msgstr "Translated msgstr"

      msgid "Fuzzy msgid"
      msgid_plural "Plural fuzzy"
      msgstr[0] ""
      msgstr[1] ""
      msgstr[2] ""

      msgid "Another msgid"
      msgstr "Another translated msgstr"
      EOF

      expect(subject.clean_po(input)).to eq(expected)
    end

  end

end
