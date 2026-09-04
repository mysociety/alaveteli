# == Schema Information
#
# Table name: censor_rules
#
#  id                :integer          not null, primary key
#  text              :text             not null
#  replacement       :text             not null
#  last_edit_editor  :string           not null
#  last_edit_comment :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  regexp            :boolean          default(FALSE), not null
#  case_sensitive    :boolean          default(TRUE), not null
#  ignore_diacritics :boolean          default(FALSE), not null
#  censorable_type   :string
#  censorable_id     :bigint
#

require 'spec_helper'

RSpec.describe CensorRule do
  describe '.info_request' do
    subject { described_class.info_request }

    let(:global_rule) { FactoryBot.create(:global_censor_rule) }
    let(:request_rule) { FactoryBot.create(:info_request_censor_rule) }

    it { is_expected.to include(request_rule) }
    it { is_expected.not_to include(global_rule) }
  end

  describe '.public_body' do
    subject { described_class.public_body }

    let(:global_rule) { FactoryBot.create(:global_censor_rule) }
    let(:public_body_rule) { FactoryBot.create(:public_body_censor_rule) }

    it { is_expected.to include(public_body_rule) }
    it { is_expected.not_to include(global_rule) }
  end

  describe '.user' do
    subject { described_class.user }

    let(:global_rule) { FactoryBot.create(:global_censor_rule) }
    let(:user_rule) { FactoryBot.create(:user_censor_rule) }

    it { is_expected.to include(user_rule) }
    it { is_expected.not_to include(global_rule) }
  end

  describe '.global' do
    subject { described_class.global }

    let(:global_rule) { FactoryBot.create(:global_censor_rule) }
    let(:user_rule) { FactoryBot.create(:user_censor_rule) }

    it { is_expected.to include(global_rule) }
    it { is_expected.not_to include(user_rule) }
  end

  describe '#update' do
    context 'when the rule has redactions' do
      let(:rule) { FactoryBot.create(:global_censor_rule) }
      let(:redactable) { FactoryBot.create(:info_request) }

      before do
        rule.redactions.create!(redactable: redactable,
                                redacted_attribute: 'body')
      end

      it 'clears redactions when text is changed' do
        expect { rule.update!(text: 'new pattern') }.
          to change(rule.redactions, :count).by(-1)
      end

      it 'clears redactions when regexp is changed' do
        expect { rule.update!(regexp: true) }.
          to change(rule.redactions, :count).by(-1)
      end

      it 'clears redactions when case_sensitive is changed' do
        expect { rule.update!(case_sensitive: false) }.
          to change(rule.redactions, :count).by(-1)
      end

      it 'clears redactions when regexp is changed' do
        expect { rule.update!(ignore_diacritics: true) }.
          to change(rule.redactions, :count).by(-1)
      end

      it 'does not clear redactions when other fields change' do
        expect { rule.update!(replacement: 'new replacement') }.
          not_to change(rule.redactions, :count)
      end
    end
  end

  describe 'after_commit callbacks' do
    it 'expires requests after create' do
      rule = FactoryBot.create(:global_censor_rule)
      expect(rule).to receive(:expire_requests)
      rule.run_callbacks(:commit)
    end

    it 'expires requests after update' do
      rule = FactoryBot.create(:global_censor_rule)
      rule.update!(text: 'updated text')
      expect(rule).to receive(:expire_requests)
      rule.run_callbacks(:commit)
    end

    it 'expires requests after destroy' do
      rule = FactoryBot.create(:global_censor_rule)
      rule.destroy!
      expect(rule).to receive(:expire_requests)
      rule.run_callbacks(:commit)
    end
  end

  describe '#global?' do
    subject { rule.global? }

    context 'without a censorable' do
      let(:rule) { FactoryBot.build(:global_censor_rule) }
      it { is_expected.to eq(true) }
    end

    context 'with a censorable' do
      let(:rule) { FactoryBot.build(:user_censor_rule) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#apply_to_text' do
    it 'applies the rule to the text' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      expect(rule.apply_to_text(text)).to eq('Some [REDACTED] text')
    end

    it 'does not mutate the input' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      rule.apply_to_text(text)
      expect(text).to eq('Some secret text')
    end

    it 'returns the text if the rule is unmatched' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some text'
      expect(rule.apply_to_text(text)).to eq('Some text')
    end

    it 'replaces the regexp with the replacement text when applied to text' do
      attrs = { text: '--PRIVATE.*--PRIVATE',
                replacement: "--REMOVED\nHidden private info\n--REMOVED",
                regexp: true }
      rule = FactoryBot.build(:censor_rule, attrs)
      text = <<-EOF.strip_heredoc
      Some public information
      --PRIVATE
      Some private information
      --PRIVATE
      EOF

      expect(rule.apply_to_text(text)).to eq <<-EOF.strip_heredoc
      Some public information
      --REMOVED
      Hidden private info
      --REMOVED
      EOF
    end

    context 'when case_sensitive is false with a non-regexp rule' do
      let(:rule) do
        FactoryBot.build(:censor_rule, :case_insensitive, text: 'Secret')
      end

      it 'applies to text regardless of case' do
        expect(rule.apply_to_text('SECRET text')).to eq('[REDACTED] text')
        expect(rule.apply_to_text('secret text')).to eq('[REDACTED] text')
      end

      it 'escapes regexp metacharacters in text' do
        rule.text = 'foo.bar'
        expect(rule.apply_to_text('fooXbar')).to eq('fooXbar')
        expect(rule.apply_to_text('foo.bar')).to eq('[REDACTED]')
      end
    end

    context 'when sensitive to both diacritics and case' do
      let(:rule) do
        FactoryBot.build(
          :censor_rule,
          ignore_diacritics: false,
          case_sensitive: true,
          text: 'ecole'
        )
      end

      it 'only matches the given text' do
        expect(rule.apply_to_text('ecole text')).to eq('[REDACTED] text')
        expect(rule.apply_to_text('école text')).to eq('école text')
        expect(rule.apply_to_text('Ecole text')).to eq('Ecole text')
        expect(rule.apply_to_text('ECOLE text')).to eq('ECOLE text')
        expect(rule.apply_to_text('ÉCOLE text')).to eq('ÉCOLE text')
      end
    end

    context 'when case_sensitive is false with regexp rule' do
      let(:rule) do
        FactoryBot.build(
          :censor_rule, :case_insensitive, regexp: true, text: 'sec+ret'
        )
      end

      it 'applies to text regardless of case' do
        expect(rule.apply_to_text('SECRET text')).to eq('[REDACTED] text')
        expect(rule.apply_to_text('secret text')).to eq('[REDACTED] text')
      end
    end

    context 'when ignore_diacritics is true' do
      let(:rule) do
        FactoryBot.build(:censor_rule, :ignore_diacritics, text: 'ecole')
      end

      it 'matches diacritic variants of the same case' do
        expect(rule.apply_to_text('ecole text')).to eq('[REDACTED] text')
        expect(rule.apply_to_text('école text')).to eq('[REDACTED] text')
      end

      it 'handles multiple diacritics in the text' do
        rule.text = 'maçã'
        expect(rule.apply_to_text('Uma maçã por dia')).
          to eq('Uma [REDACTED] por dia')
      end

      it 'handles multi-letter diacritics' do
        rule.text = 'œuf'
        expect(rule.apply_to_text('Un œuf, des oeufs')).
          to eq('Un [REDACTED], des [REDACTED]s')
      end

      it 'does not match the opposite case' do
        expect(rule.apply_to_text('Ecole text')).to eq('Ecole text')
        expect(rule.apply_to_text('ECOLE text')).to eq('ECOLE text')
        expect(rule.apply_to_text('ÉCOLE text')).to eq('ÉCOLE text')
      end
    end

    context 'when ignoring diacritics and case' do
      let(:rule) do
        FactoryBot.build(
          :censor_rule,
          :ignore_diacritics,
          :case_insensitive,
          text: 'ecole'
        )
      end

      it 'matches diacritic variants in any case' do
        expect(rule.apply_to_text('ecole text')).to eq('[REDACTED] text')
        expect(rule.apply_to_text('école text')).to eq('[REDACTED] text')
        expect(rule.apply_to_text('Ecole text')).to eq('[REDACTED] text')
        expect(rule.apply_to_text('ECOLE text')).to eq('[REDACTED] text')
        expect(rule.apply_to_text('ÉCOLE text')).to eq('[REDACTED] text')
      end
    end

    describe 'recording redactions' do
      let(:rule) { FactoryBot.create(:global_censor_rule, text: 'secret') }
      let(:redactable) { FactoryBot.create(:info_request) }

      it 'creates a redaction row when the rule matches' do
        expect {
          rule.apply_to_text(
            'contains secret text',
            redactable: redactable, redacted_attribute: :body
          )
        }.to change(rule.redactions, :count).by(1)
      end

      it 'does not create a redaction row when the rule does not match' do
        expect {
          rule.apply_to_text(
            'no match here', redactable: redactable, redacted_attribute: :body
          )
        }.not_to change(rule.redactions, :count)
      end

      it 'does not create a redaction row when no redactable is given' do
        expect {
          rule.apply_to_text('contains secret text')
        }.not_to change(rule.redactions, :count)
      end

      it 'deletes an existing redaction row when the rule no longer matches' do
        rule.apply_to_text(
          'contains secret text',
          redactable: redactable, redacted_attribute: :body
        )
        expect {
          rule.apply_to_text(
            'no match here', redactable: redactable, redacted_attribute: :body
          )
        }.to change(rule.redactions, :count).by(-1)
      end

      it 'keeps separate rows per attribute on the same redactable' do
        rule.apply_to_text(
          'secret body', redactable: redactable, redacted_attribute: :body
        )

        rule.apply_to_text(
          'secret title', redactable: redactable, redacted_attribute: :title
        )

        redactions = rule.redactions.where(redactable: redactable)

        expect(redactions.pluck(:redacted_attribute)).
          to match_array(%w[body title])
      end
    end
  end

  describe '#apply_to_binary' do
    it 'applies the rule to the text' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      expect(rule.apply_to_binary(text)).to eq('Some xxxxxx text')
    end

    it 'does not modify the size of the string' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      original_text = text.dup
      redacted = rule.apply_to_binary(text)
      expect(redacted.bytesize).to eq(original_text.bytesize)
    end

    it 'does not modify the size of UTF-8 string' do
      rule = FactoryBot.build(:censor_rule, text: 'sécret')
      text = 'Some sécret text'
      original_text = text.dup
      redacted = rule.apply_to_binary(text)
      expect(redacted.bytesize).to eq(original_text.bytesize)
    end

    it 'does not mutate the input' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some secret text'
      rule.apply_to_binary(text)
      expect(text).to eq('Some secret text')
    end

    it 'returns the text if the rule is unmatched' do
      rule = FactoryBot.build(:censor_rule, text: 'secret')
      text = 'Some text'
      expect(rule.apply_to_binary(text)).to eq('Some text')
    end

    it 'handles UTF-8 text' do
      rule = FactoryBot.build(:censor_rule, text: 'sécret')
      text = 'Some sécret text'
      text.force_encoding('UTF-8')
      expect(rule.apply_to_binary(text)).to eq("Some xxxxxxx text")
    end

    it 'handles a UTF-8 rule and ASCII-8BIT text' do
      rule = FactoryBot.build(:censor_rule, text: 'sécret')
      text = 'Some sécret text'
      text.force_encoding('ASCII-8BIT')
      expect(rule.apply_to_binary(text)).to eq("Some xxxxxxx text")
    end

    it "replaces the regexp with the same number of 'x' characters as the text
        replaced when applied to binary" do
      attrs = { text: '--PRIVATE.*--PRIVATE',
                replacement: "--REMOVED\nHidden private info\n--REMOVED",
                regexp: true }
      rule = FactoryBot.build(:censor_rule, attrs)
      text = <<-EOF.strip_heredoc
      Some public information
      --PRIVATE
      Some private information
      --PRIVATE
      EOF

      expect(rule.apply_to_binary(text)).to eq <<-EOF.strip_heredoc
      Some public information
      xxxxxxxxx
      xxxxxxxxxxxxxxxxxxxxxxxx
      xxxxxxxxx
      EOF
    end

    it 'handles a UTF-8 rule with ASCII-8BIT text' do
      attrs = { text: '--PRIVATE.*--P‘RIVATE',
                replacement: "--REMOVED\nHidden private info\n--REMOVED",
                regexp: true }
      rule = FactoryBot.build(:censor_rule, attrs)
      text = <<-EOF.strip_heredoc
      Some public information
      --PRIVATE
      Some private information
      --P‘RIVATE
      EOF
      text.force_encoding('ASCII-8BIT')

      expect(rule.apply_to_binary(text)).to eq <<-EOF.strip_heredoc
      Some public information
      xxxxxxxxx
      xxxxxxxxxxxxxxxxxxxxxxxx
      xxxxxxxxxxxx
      EOF
    end

    context 'when case_sensitive is false with a non-regexp rule' do
      let(:rule) do
        FactoryBot.build(:censor_rule, :case_insensitive, text: 'Secret')
      end

      it 'applies to binary regardless of case' do
        expect(rule.apply_to_binary('SECRET text')).to eq('xxxxxx text')
        expect(rule.apply_to_binary('secret text')).to eq('xxxxxx text')
      end

      it 'escapes regexp metacharacters in binary' do
        rule.text = 'foo.bar'
        expect(rule.apply_to_binary('fooXbar')).to eq('fooXbar')
        expect(rule.apply_to_binary('foo.bar')).to eq('xxxxxxx')
      end
    end

    context 'when sensitive to both diacritics and case' do
      let(:rule) do
        FactoryBot.build(
          :censor_rule,
          ignore_diacritics: false,
          case_sensitive: true,
          text: 'ecole'
        )
      end

      it 'only matches the given text' do
        expect(rule.apply_to_binary('ecole text')).to eq('xxxxx text')
        expect(rule.apply_to_binary('école text')).to eq('école text')
        expect(rule.apply_to_binary('Ecole text')).to eq('Ecole text')
        expect(rule.apply_to_binary('ECOLE text')).to eq('ECOLE text')
        expect(rule.apply_to_binary('ÉCOLE text')).to eq('ÉCOLE text')
      end
    end

    context 'when case_sensitive is false with a regexp rule' do
      let(:rule) do
        FactoryBot.build(
          :censor_rule, :case_insensitive, regexp: true, text: 'sec+ret'
        )
      end

      it 'applies to binary regardless of case' do
        expect(rule.apply_to_binary('SECRET text')).to eq('xxxxxx text')
        expect(rule.apply_to_binary('secret text')).to eq('xxxxxx text')
      end
    end

    context 'when ignore_diacritics is true' do
      let(:rule) do
        FactoryBot.build(:censor_rule, :ignore_diacritics, text: 'ecole')
      end

      it 'matches diacritic variants of the same case in binary' do
        expect(rule.apply_to_binary('école text')).to eq('xxxxxx text')
      end

      it 'handles multiple diacritics in the text' do
        rule.text = 'maçã'
        expect(rule.apply_to_binary('Uma maçã por dia')).
          to eq('Uma xxxxxx por dia')
      end

      it 'handles multi-letter diacritics' do
        rule.text = 'œuf'
        expect(rule.apply_to_binary('Un œuf, des oeufs')).
          to eq('Un xxxx, des xxxxs')
      end

      it 'does not match the opposite case in binary' do
        expect(rule.apply_to_binary('École text')).to eq('École text')
      end
    end

    context 'when ignoring diacritics and case' do
      let(:rule) do
        FactoryBot.build(
          :censor_rule,
          :ignore_diacritics,
          :case_insensitive,
          text: 'ecole'
        )
      end

      it 'matches diacritic variants in any case in binary' do
        expect(rule.apply_to_binary('ECOLE text')).to eq('xxxxx text')
        expect(rule.apply_to_binary('école text')).to eq('xxxxxx text')
      end
    end

    describe 'recording redactions' do
      let(:rule) { FactoryBot.create(:global_censor_rule, text: 'secret') }
      let(:redactable) { FactoryBot.create(:info_request) }

      it 'creates a redaction row when the rule matches' do
        expect {
          rule.apply_to_binary(
            'contains secret text',
            redactable: redactable, redacted_attribute: :body
          )
        }.to change(rule.redactions, :count).by(1)
      end

      it 'does not create a redaction row when the rule does not match' do
        expect {
          rule.apply_to_binary(
            'no match here', redactable: redactable, redacted_attribute: :body
          )
        }.not_to change(rule.redactions, :count)
      end
    end
  end

  describe '#expire_requests' do
    subject { rule.expire_requests }

    context 'with a censorable' do
      let(:rule) { FactoryBot.create(:info_request_censor_rule) }

      it 'expires the requests via the censorable' do
        expect(rule.censorable).to receive(:expire_requests)
        subject
      end
    end

    context 'with a global rule' do
      let!(:rule) { FactoryBot.create(:global_censor_rule) }

      it 'expires the requests directly' do
        expect { subject }.
          to have_enqueued_job(InfoRequest::ExpireJob).with(InfoRequest, :all)
      end
    end
  end

  describe '#censorable_requests' do
    subject { censor_rule.censorable_requests }

    context 'with an info_request censor rule' do
      let(:censor_rule) { FactoryBot.create(:info_request_censor_rule) }
      it { is_expected.to match_array([censor_rule.censorable]) }
    end

    context 'with a public_body censor rule' do
      let(:censor_rule) { FactoryBot.create(:public_body_censor_rule) }
      let(:censorable) { censor_rule.censorable }

      before { FactoryBot.create(:info_request, public_body: censorable) }

      it { is_expected.to match_array(censorable.info_requests) }
    end

    context 'with a user censor rule' do
      let(:censor_rule) { FactoryBot.create(:user_censor_rule) }
      let(:censorable) { censor_rule.censorable }

      before { FactoryBot.create(:info_request, user: censorable) }

      it { is_expected.to match_array(censorable.info_requests) }
    end

    context 'with a global censor rule' do
      let(:censor_rule) { FactoryBot.create(:global_censor_rule) }
      it { is_expected.to eq(InfoRequest.unscoped) }
    end
  end

  describe '#censorable' do
    subject { censor_rule.censorable }

    context 'with an info_request censor rule' do
      let(:censor_rule) { FactoryBot.build(:info_request_censor_rule) }
      it { is_expected.to be_an(InfoRequest) }
    end

    context 'with a public_body censor rule' do
      let(:censor_rule) { FactoryBot.build(:public_body_censor_rule) }
      it { is_expected.to be_a(PublicBody) }
    end

    context 'with a user censor rule' do
      let(:censor_rule) { FactoryBot.build(:user_censor_rule) }
      it { is_expected.to be_a(User) }
    end

    context 'with a global censor rule' do
      let(:censor_rule) { FactoryBot.build(:global_censor_rule) }
      it { is_expected.to be_nil }
    end
  end
end

RSpec.describe 'when validating rules' do
  it 'must have the text to redact' do
    censor_rule = CensorRule.new
    censor_rule.valid?
    expect(censor_rule.errors[:text].size).to eq(1)
    expect(censor_rule.errors[:text]).to eql(["can't be blank"])
  end

  it 'must have a replacement' do
    censor_rule = CensorRule.new
    censor_rule.valid?
    expect(censor_rule.errors[:replacement].size).to eq(1)
  end

  it 'must have a last_edit_editor' do
    censor_rule = CensorRule.new
    censor_rule.valid?
    expect(censor_rule.errors[:last_edit_editor].size).to eq(1)
  end

  it 'must have a last_edit_comment' do
    censor_rule = CensorRule.new
    censor_rule.valid?
    expect(censor_rule.errors[:last_edit_comment].size).to eq(1)
  end

  describe 'when validating an ignore_diacritics rule' do
    let(:rule) do
      CensorRule.new(ignore_diacritics: true,
                     text: 'ecole',
                     replacement: '[REDACTED]',
                     last_edit_comment: 'test',
                     last_edit_editor: 'rspec')
    end

    it 'is valid' do
      expect(rule).to be_valid
    end
  end

  describe 'when validating a regexp with ignore_diacritics rule' do
    let(:rule) do
      CensorRule.new(regexp: true,
                     ignore_diacritics: true,
                     text: 'ecole',
                     replacement: '[REDACTED]',
                     last_edit_comment: 'test',
                     last_edit_editor: 'rspec')
    end

    it 'is not valid' do
      expect(rule).not_to be_valid
    end

    it 'adds an error on text' do
      rule.valid?
      expect(rule.errors[:text]).to include(
        'Cannot use regexp and ignore diacritics option together'
      )
    end
  end

  describe 'when validating a regexp rule' do
    before do
      @censor_rule = CensorRule.new(regexp: true,
                                    text: '*',
                                    replacement: '---',
                                    last_edit_comment: 'test',
                                    last_edit_editor: 'rspec')
    end

    it 'should try to create a regexp from the text' do
      expect(Regexp).to receive(:new).with('*', Regexp::MULTILINE)
      @censor_rule.valid?
    end

    describe 'if a regexp error is produced' do
      it 'should add an error message to the text field with the regexp error message' do
        allow(Regexp).to receive(:new).and_raise(RegexpError.new("very bad regexp"))
        expect(@censor_rule.valid?).to eq(false)
        expect(@censor_rule.errors[:text]).to eq(["very bad regexp"])
      end
    end

    describe 'if a regexp contains unescaped characters' do
      before { @censor_rule.text = 'foo]' }

      it 'does not output a warning' do
        expect { @censor_rule.valid? }.not_to output.to_stderr
      end

      it 'adds an error message to the text field' do
        msg = "regular expression has ']' without escape: /foo]/"
        @censor_rule.valid?
        expect(@censor_rule.errors[:text]).to eq([msg])
      end
    end

    describe 'if no regexp error is produced' do
      it 'should not add any error message to the text field' do
        allow(Regexp).to receive(:new)
        @censor_rule.valid?
        expect(@censor_rule.errors[:text]).to eq([])
      end
    end
  end
end
