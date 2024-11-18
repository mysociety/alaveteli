# == Schema Information
# Schema version: 20210114161442
#
# Table name: info_request_batches
#
#  id               :integer          not null, primary key
#  title            :text             not null
#  user_id          :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  body             :text
#  sent_at          :datetime
#  embargo_duration :string
#

require 'spec_helper'
require 'models/concerns/info_request/title_validation'

RSpec.describe InfoRequestBatch do
  it_behaves_like 'concerns/info_request/title_validation', :info_request_batch

  it { is_expected.to strip_attribute(:embargo_duration) }

  context "when validating" do
    let(:info_request_batch) { FactoryBot.build(:info_request_batch) }

    it 'should require a user' do
      info_request_batch.user = nil
      expect(info_request_batch.valid?).to be false
      expect(info_request_batch.errors.full_messages).to eq(["User can't be blank"])
    end

    it 'should require a body' do
      info_request_batch.body = nil
      expect(info_request_batch.valid?).to be false
      expect(info_request_batch.errors.full_messages).to eq(["Body can't be blank"])
    end

    context 'without ignore_existing_batch argument being set' do
      it 'requires batch to be unique without an existing batch' do
        allow(info_request_batch).to receive(:existing_batch).and_return(double)
        expect(info_request_batch.valid?).to eq false
        expect(info_request_batch.errors.full_messages).to eq(
          ['Existing batch must be blank']
        )
      end
    end

    context 'when batch has already been saved' do
      let(:info_request_batch) { FactoryBot.create(:info_request_batch) }

      it 'valid when an existing batch is found' do
        allow(info_request_batch).to receive(:existing_batch).and_return(double)
        expect(info_request_batch.valid?).to eq true
      end
    end

    context 'with ignore_existing_batch argument being set' do
      it 'valid when an existing batch is found' do
        info_request_batch.ignore_existing_batch = true
        allow(info_request_batch).to receive(:existing_batch).and_return(double)
        expect(info_request_batch.valid?).to eq true
      end
    end
  end

  describe '.not_embargoed' do
    subject { described_class.not_embargoed }

    let(:not_embargoed) { FactoryBot.create(:info_request_batch) }
    let(:embargoed) { FactoryBot.create(:info_request_batch, :embargoed) }

    it { is_expected.to include(not_embargoed) }
    it { is_expected.not_to include(embargoed) }
  end

  context '.with_body' do
    let(:batch) do
      FactoryBot.create(:info_request_batch, body: "foo\n\nbar")
    end

    it 'returns batch if body matches exactly' do
      expect(InfoRequestBatch.with_body("foo\r\nbar")).to include(batch)
    end

    it 'matchs batch body when whitespace is ignored' do
      ['foobar', 'foo bar', "foo\nbar"].each do |str|
        expect(InfoRequestBatch.with_body(str)).to include(batch)
      end
    end

    it 'matchs whole batch body' do
      strings = ['foo', 'foobarbaz', 'foo bar baz', "foo\nbar\nbaz",
                 "foo\r\nbar\r\nbaz"]
      strings.each do |str|
        expect(InfoRequestBatch.with_body(str)).to_not include(batch)
      end
    end
  end

  context "when finding an existing batch" do
    let(:first_body) { FactoryBot.create(:public_body) }
    let(:second_body) { FactoryBot.create(:public_body) }
    let(:info_request_batch) do
      FactoryBot.create(:info_request_batch, title: 'Matched title',
                                             body: 'Matched body',
                                             public_bodies: [first_body,
                                                                second_body])
    end

    it 'should return a batch with the same user, title and body sent to one of the same public bodies' do
      expect(InfoRequestBatch.find_existing(info_request_batch.user,
                                            info_request_batch.title,
                                            info_request_batch.body,
                                            [first_body])).not_to be_nil
    end

    it 'should not return a batch with the same title and body sent to another public body' do
      expect(InfoRequestBatch.find_existing(info_request_batch.user,
                                            info_request_batch.title,
                                            info_request_batch.body,
                                            [FactoryBot.create(:public_body)])).to be_nil
    end

    it 'should not return a batch sent to the same public bodies with a different title and body' do
      expect(InfoRequestBatch.find_existing(info_request_batch.user,
                                            'Other title',
                                            'Other body',
                                            [first_body])).to be_nil
    end

    it 'should not return a batch sent to one of the same public bodies with the same title and body by
          a different user' do
      expect(InfoRequestBatch.find_existing(FactoryBot.create(:user),
                                            info_request_batch.title,
                                            info_request_batch.body,
                                            [first_body])).to be_nil
    end

    it 'should not return a batch with a matching ID' do
      expect(
        InfoRequestBatch.find_existing(
          info_request_batch.user,
          info_request_batch.title,
          info_request_batch.body,
          info_request_batch.public_bodies,
          id: info_request_batch.id
        )
      ).to be_nil
    end
  end

  context '#existing_batch' do
    let(:user) { existing_batch.user }
    let(:title) { existing_batch.title }
    let(:body) { existing_batch.body }
    let(:public_bodies) { existing_batch.public_bodies }

    let!(:existing_batch) do
      FactoryBot.create(
        :info_request_batch,
        title: 'Batch title',
        body: 'Batch body',
        public_bodies: [
          FactoryBot.build(:public_body),
          FactoryBot.build(:public_body)
        ]
      )
    end

    let(:info_request_batch) do
      FactoryBot.build(
        :info_request_batch,
        user: user, title: title, body: body,
        public_bodies: public_bodies
      )
    end

    subject { info_request_batch.existing_batch }

    context 'with same user, title, body and public bodies' do
      it 'returns the existing batch' do
        is_expected.to eq(existing_batch)
      end
    end

    context 'with any of the existing public bodies' do
      let(:public_bodies) { [existing_batch.public_bodies.first] }

      it 'returns the existing batch' do
        is_expected.to eq(existing_batch)
      end
    end

    context 'with a different public bodies' do
      let(:public_bodies) { [FactoryBot.build(:public_body)] }
      it { is_expected.to be_nil }
    end

    context 'with a different user' do
      let(:user) { FactoryBot.build(:user) }
      it { is_expected.to be_nil }
    end

    context 'with a different title' do
      let(:title) { 'New title' }
      it { is_expected.to be_nil }
    end

    context 'with a different body' do
      let(:body) { 'New body' }
      it { is_expected.to be_nil }
    end

    context 'as the same batch' do
      let(:info_request_batch) { existing_batch }
      it { is_expected.to be_nil }
    end
  end

  context "when creating a batch" do
    let(:first_public_body) { FactoryBot.create(:public_body) }
    let(:second_public_body) { FactoryBot.create(:public_body) }
    let(:info_request_batch) do
      FactoryBot.create(
        :info_request_batch,
        body: "Dear [Authority name],\nA message\nYours faithfully,\nRequester",
        public_bodies: [first_public_body, second_public_body])
    end

    it 'should substitute authority name for the placeholder in each request' do
      info_request_batch.create_batch!
      [first_public_body, second_public_body].each do |public_body|
        request = info_request_batch.info_requests.detect do |info_request|
          info_request.public_body == public_body
        end
        expected = "Dear #{public_body.name},\nA message\nYours faithfully,\nRequester"
        expect(request.outgoing_messages.first.body).to eq(expected)
      end
    end

    it 'does not resend requests to public bodies that have already received the request' do
      allow(info_request_batch).to receive(:requestable_public_bodies).
        and_return([first_public_body])
      expect { info_request_batch.create_batch! }.to(
        change(info_request_batch.info_requests, :count).by(1)
      )
      request = info_request_batch.info_requests.first
      expect(request.outgoing_messages.first.status).to eq('sent')
    end

    it 'should not only send requests to public bodies if already sent' do
      info_request_batch.info_requests = [
        FactoryBot.create(:info_request, public_body: first_public_body)
      ]
      expect { info_request_batch.create_batch! }.to(
        change(info_request_batch.info_requests, :count).by(1)
      )
    end

    it "it imposes an alphabetical sort order on associated public bodies" do
      third_public_body = FactoryBot.create(:public_body,
                                            name: "Another Body")
      batch = FactoryBot.create(
        :info_request_batch,
        public_bodies: [first_public_body,
                           third_public_body])
      batch.reload
      expect(batch.public_bodies).to eq([third_public_body,
                                          first_public_body])
    end

    it 'returns a distinct list of associated public bodies' do
      public_body = FactoryBot.create(
        :public_body,
        translations_attributes: {
          'en' => { locale: 'en', name: 'Welsh Government' },
          'cy' => { locale: 'cy', name: 'Llywodraeth Cymru' }
        }
      )
      batch = FactoryBot.create(
        :info_request_batch, public_bodies: [public_body]
      )

      expect(batch.public_bodies.count).to eq(1)
      expect(batch.public_bodies).to match_array([public_body])
    end

    context "when embargo_duration is set" do
      it 'should set an embargo on each request' do
        info_request_batch.embargo_duration = '3_months'
        info_request_batch.create_batch!
        [first_public_body, second_public_body].each do |public_body|
          request = info_request_batch.info_requests.detect do |info_request|
            info_request.public_body == public_body
          end
          expect(request.embargo).not_to be_nil
          expect(request.embargo.embargo_duration).to eq "3_months"
        end
      end
    end
  end

  context "when sending batches" do
    let(:first_public_body) { FactoryBot.create(:public_body) }
    let(:second_public_body) { FactoryBot.create(:public_body) }
    let!(:info_request_batch) do
      FactoryBot.create(
        :info_request_batch,
        title: 'Example title',
        public_bodies: [first_public_body, second_public_body])
    end
    let!(:sent_batch) do
      FactoryBot.create(
        :info_request_batch,
        public_bodies: [first_public_body, second_public_body],
        sent_at: Time.zone.now)
    end

    it 'should send requests and notifications for only unsent batch requests' do
      InfoRequestBatch.send_batches
      expect(deliveries.size).to eq(3)
      first_mail = deliveries.first
      expect(first_mail.to).to eq([first_public_body.request_email])
      expect(first_mail.subject).to eq('Freedom of Information request - Example title')

      second_mail = deliveries.second
      expect(second_mail.to).to eq([second_public_body.request_email])
      expect(second_mail.subject).to eq('Freedom of Information request - Example title')

      third_mail = deliveries.third
      expect(third_mail.to).to eq([info_request_batch.user.email])
      expect(third_mail.subject).to eq('Your batch request "Example title" has been sent')
    end

    it 'should set the sent_at value of the info request batch' do
      InfoRequestBatch.send_batches
      expect { info_request_batch.reload }.to(
        change(info_request_batch, :sent_at).from(nil).to(Time)
      )
    end

    context 'when the user has a non-default locale' do
      let!(:user) { FactoryBot.create(:user, locale: :es) }

      let!(:info_request_batch) do
        FactoryBot.create(
          :info_request_batch,
          user: user,
          body: "Dear [Authority name],\n\nSome text",
          public_bodies: [first_public_body, second_public_body]
        )
      end

      before { described_class.send_batches }

      it 'sends the batches with the template for the user locale' do
        info_request = info_request_batch.reload.info_requests.first
        message_body = info_request.outgoing_messages.first.body
        public_body_name = info_request.public_body.name

        expect(message_body).to include("Estimado #{ public_body_name }")
      end
    end
  end

  describe "#from_draft" do
    let(:first_public_body) { FactoryBot.create(:public_body) }
    let(:second_public_body) { FactoryBot.create(:public_body) }
    let(:draft) do
      FactoryBot.create(
        :draft_info_request_batch,
        public_bodies: [first_public_body, second_public_body])
    end

    it "copies across all of the attributes from the draft" do
      batch = InfoRequestBatch.from_draft(draft)
      expect(batch.title).to eq draft.title
      expect(batch.body).to eq draft.body
      expect(batch.public_bodies).to eq draft.public_bodies
      expect(batch.embargo_duration).to eq draft.embargo_duration
    end

    it "doesn't save the batch" do
      batch = InfoRequestBatch.from_draft(draft)
      expect(batch.persisted?).to be false
    end
  end

  describe '#sent?' do
    subject { batch.sent? }

    context 'sent_at has been set' do
      let(:batch) { FactoryBot.create(:info_request_batch, :sent) }
      it { is_expected.to eq true }
    end

    context 'sent_at has not been set' do
      let(:batch) { FactoryBot.create(:info_request_batch) }
      it { is_expected.to eq false }
    end
  end

  describe "#example_request" do
    let(:first_public_body) { FactoryBot.create(:public_body) }
    let(:second_public_body) { FactoryBot.create(:public_body) }

    context "when the batch has an embargo duration" do
      let(:info_request_batch) do
        FactoryBot.create(
          :info_request_batch,
          public_bodies: [first_public_body, second_public_body],
          embargo_duration: "3_months")
      end
      let(:example) { info_request_batch.example_request }

      it "builds, but doesn't save the request" do
        expect(example.persisted?).to be false
      end

      it "copies the title from the batch into the request" do
        expect(example.title).to eq info_request_batch.title
      end

      it "fills out the salutation in the body with the public body name" do
        info_request_batch.body = "Dear [Authority name],\n\nSome request"
        info_request_batch.save!
        expected_body = info_request_batch.body.gsub(
          "[Authority name]",
          info_request_batch.public_bodies.first.name)
        expect(example.outgoing_messages.first.body).to eq expected_body
      end

      it "creates an example request for the first body in the batch" do
        expect(example.public_body).to eq info_request_batch.public_bodies.first
      end

      it "creates an example request with an embargo" do
        expect(example.embargo.embargo_duration).to eq '3_months'
        expect(example.embargo.persisted?).to be false
      end
    end

    context "when the batch doesn't have an embargo duration" do
      let(:info_request_batch) do
        FactoryBot.create(
          :info_request_batch,
          public_bodies: [first_public_body, second_public_body])
      end
      let(:example) { info_request_batch.example_request }

      it "builds, but doesn't save the request" do
        expect(example.persisted?).to be false
      end

      it "copies the title from the batch into the request" do
        expect(example.title).to eq info_request_batch.title
      end

      it "fills out the salutation in the body with the public body name" do
        info_request_batch.body = "Dear [Authority name],\n\nSome request"
        info_request_batch.save!
        expected_body = info_request_batch.body.gsub(
          "[Authority name]",
          info_request_batch.public_bodies.first.name)
        expect(example.outgoing_messages.first.body).to eq expected_body
      end

      it "creates an example request for the first body in the batch" do
        expect(example.public_body).to eq info_request_batch.public_bodies.first
      end

      it "doesn't create an embargo for the example request" do
        expect(example.embargo).to be_nil
      end
    end
  end

  it_behaves_like "RequestSummaries"

  describe '#embargoed?' do
    subject { batch.embargoed? }

    let(:batch) { FactoryBot.build(:info_request_batch) }

    context 'when the batch has an embargo_duration' do
      before { batch.embargo_duration = '12_months' }
      it { is_expected.to eq(true) }
    end

    context 'when the batch has no embargo_duration' do
      before { batch.embargo_duration = nil }
      it { is_expected.to eq(false) }
    end
  end

  describe "#embargo_expiring?" do
    let(:first_public_body) { FactoryBot.create(:public_body) }
    let(:second_public_body) { FactoryBot.create(:public_body) }
    let(:info_request_batch) do
      FactoryBot.create(
        :info_request_batch,
        public_bodies: [first_public_body, second_public_body])
    end

    before do
      # We need the batch to have requests to test them out
      info_request_batch.create_batch!
    end

    context "when requests have an embargoes which are expiring" do
      before do
        info_request_batch.info_requests.each do |request|
          FactoryBot.create(:expiring_embargo, info_request: request)
        end
      end

      it "returns true" do
        expect(info_request_batch.embargo_expiring?).to be true
      end
    end

    context "when requests have embargoes but they're not expiring soon" do
      before do
        info_request_batch.info_requests.each do |request|
          FactoryBot.create(:embargo, info_request: request)
        end
      end

      it "returns false" do
        expect(info_request_batch.embargo_expiring?).to be false
      end
    end

    context "when no requests have embargoes" do
      it "returns false" do
        expect(info_request_batch.embargo_expiring?).to be false
      end
    end
  end

  describe '#can_change_embargo?' do
    subject { batch.can_change_embargo? }

    context 'the batch has been sent' do
      let(:batch) { FactoryBot.create(:info_request_batch, :sent) }
      it { is_expected.to eq true }
    end

    context 'the batch is unsent' do
      let(:batch) { FactoryBot.create(:info_request_batch) }
      it { is_expected.to eq false }
    end
  end

  describe "#request_phases" do
    let(:public_bodies) { FactoryBot.create_list(:public_body, 3) }
    let(:info_request_batch) do
      FactoryBot.create(:info_request_batch, public_bodies: public_bodies)
    end

    before do
      # We need the batch to have requests to test them out
      info_request_batch.create_batch!
      info_request_batch.reload
      # We also need them to be in a few different states to test the phases
      info_request_batch.info_requests.first.set_described_state('successful')
    end

    context "when there are requests" do
      it "returns their phases" do
        expected = [:complete, :awaiting_response]
        expect(info_request_batch.request_phases).to match_array(expected)
      end
    end
  end

  describe "#request_phases_summary" do
    let(:public_bodies) { FactoryBot.create_list(:public_body, 10) }
    let(:info_request_batch) do
      FactoryBot.create(:info_request_batch, public_bodies: public_bodies)
    end

    before do
      # We need the batch to have requests to test them out
      info_request_batch.create_batch!
      info_request_batch.reload
      # We also need them to be in a few different states to test the phases
      requests = info_request_batch.info_requests.to_a
      requests.first.set_described_state('successful')
      requests.second.set_described_state('successful')

      requests.third.set_described_state('waiting_clarification')
      requests.fourth.set_described_state('waiting_clarification')
      requests.fifth.set_described_state('waiting_clarification')

      requests.last.set_described_state('gone_postal')
    end

    it "returns summarised counts of each request phase grouping" do
      expected = {
        in_progress: {
          label: _('In progress'),
          count: 4
        },
        action_needed: {
          label: _('Action needed'),
          count: 3
        },
        complete: {
          label: _('Complete'),
          count: 2
        },
        other: {
          label: _('Other'),
          count: 1
        }
      }
      expect(info_request_batch.request_phases_summary).to eq expected
    end
  end

  describe '#sent_public_bodies' do
    subject { batch.sent_public_bodies }

    let(:sent_body) { FactoryBot.build(:public_body) }
    let(:unsent_body) { FactoryBot.build(:public_body) }

    let(:info_request) do
      FactoryBot.build(:info_request, public_body: sent_body)
    end

    let(:batch) do
      FactoryBot.create(
        :info_request_batch,
        info_requests: [info_request],
        public_bodies: [sent_body, unsent_body]
      )
    end

    it { is_expected.to include(sent_body) }
    it { is_expected.to_not include(unsent_body) }
  end

  describe '#requestable_public_bodies' do
    subject { batch.requestable_public_bodies }

    let(:sent_body) { FactoryBot.build(:public_body) }
    let(:requestable_body) { FactoryBot.build(:public_body) }
    let(:unrequestable_body) { FactoryBot.build(:blank_email_public_body) }

    let(:info_request) do
      FactoryBot.build(:info_request, public_body: sent_body)
    end

    let(:batch) do
      FactoryBot.create(
        :info_request_batch,
        info_requests: [info_request],
        public_bodies: [sent_body, requestable_body, unrequestable_body]
      )
    end

    it { is_expected.to_not include(sent_body) }
    it { is_expected.to include(requestable_body) }
    it { is_expected.to_not include(unrequestable_body) }
  end

  describe '#unrequestable_public_bodies' do
    subject { batch.unrequestable_public_bodies }

    let(:sent_body) { FactoryBot.build(:public_body) }
    let(:requestable_body) { FactoryBot.build(:public_body) }
    let(:unrequestable_body) { FactoryBot.build(:blank_email_public_body) }

    let(:info_request) do
      FactoryBot.build(:info_request, public_body: sent_body)
    end

    let(:batch) do
      FactoryBot.create(
        :info_request_batch,
        info_requests: [info_request],
        public_bodies: [sent_body, requestable_body, unrequestable_body]
      )
    end

    it { is_expected.to_not include(sent_body) }
    it { is_expected.to_not include(requestable_body) }
    it { is_expected.to include(unrequestable_body) }
  end

  describe '#all_requests_created?' do
    subject { batch.all_requests_created? }

    let(:batch) { FactoryBot.build(:info_request_batch) }
    let(:body) { FactoryBot.build(:public_body) }

    context 'there no requestable public bodies' do
      before { allow(batch).to receive(:requestable_public_bodies) { [] } }
      it { is_expected.to eq true }
    end

    context 'there are requestable public bodies' do
      before { allow(batch).to receive(:requestable_public_bodies) { [body] } }
      it { is_expected.to eq false }
    end
  end

  describe '#should_summarise?' do
    subject { batch.should_summarise? }

    let!(:batch) do
      FactoryBot.create(
        :info_request_batch,
        public_bodies: [FactoryBot.build(:public_body)],
        request_summary: FactoryBot.build(:request_summary)
      )
    end

    it { is_expected.to eq false }

    context 'without summary' do
      before { batch.request_summary = nil }
      it { is_expected.to eq true }
    end

    context 'all requests have been created' do
      before { allow(batch).to receive(:all_requests_created?) { true } }
      it { is_expected.to eq true }
    end
  end

  describe "#log_event" do
    let(:public_bodies) { FactoryBot.create_list(:public_body, 3) }
    let(:info_request_batch) do
      FactoryBot.create(:info_request_batch, public_bodies: public_bodies)
    end

    before do
      # We need the batch to have requests to test them out
      info_request_batch.create_batch!
    end

    it 'calls `log_event` on all information requests in a batch' do
      arguments = double(:args)
      info_request_batch.info_requests.each do |request|
        expect(request).to receive(:log_event).with(arguments)
      end
      info_request_batch.log_event(arguments)
    end
  end

  describe '#is_owning_user?' do
    subject { info_request_batch.is_owning_user?(user) }

    let(:info_request_batch) { FactoryBot.create(:info_request_batch) }

    context 'with no user' do
      let(:user) { nil }
      it { is_expected.to eq(false) }
    end

    context 'with the batch owner' do
      let(:user) { info_request_batch.user }
      it { is_expected.to eq(true) }
    end

    context 'with an admin' do
      let(:user) { mock_model(User, owns_every_request?: true) }
      it { is_expected.to eq(true) }
    end

    context 'with a non-owner user' do
      let(:user) { mock_model(User, owns_every_request?: false) }
      it { is_expected.to eq(false) }
    end
  end

  describe '#prominence' do
    subject { info_request_batch.prominence }
    let(:info_request_batch) { FactoryBot.build(:info_request_batch) }
    it { is_expected.to eq('normal') }
  end
end
