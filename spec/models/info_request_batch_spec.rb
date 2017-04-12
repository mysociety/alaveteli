# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_request_batches
#
#  id         :integer          not null, primary key
#  title      :text             not null
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  body       :text
#  sent_at    :datetime
#

require 'spec_helper'

describe InfoRequestBatch do
  context "when validating" do
    let(:info_request_batch) { FactoryGirl.build(:info_request_batch) }

    it 'should require a user' do
      info_request_batch.user = nil
      expect(info_request_batch.valid?).to be false
      expect(info_request_batch.errors.full_messages).to eq(["User can't be blank"])
    end

    it 'should require a title' do
      info_request_batch.title = nil
      expect(info_request_batch.valid?).to be false
      expect(info_request_batch.errors.full_messages).to eq(["Title can't be blank"])
    end

    it 'should require a body' do
      info_request_batch.body = nil
      expect(info_request_batch.valid?).to be false
      expect(info_request_batch.errors.full_messages).to eq(["Body can't be blank"])
    end

  end

  context "when finding an existing batch" do
    let(:first_body) { FactoryGirl.create(:public_body) }
    let(:second_body) { FactoryGirl.create(:public_body) }
    let(:info_request_batch) do
      FactoryGirl.create(:info_request_batch, :title => 'Matched title',
                                              :body => 'Matched body',
                                              :public_bodies => [first_body,
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
                                            [FactoryGirl.create(:public_body)])).to be_nil
    end

    it 'should not return a batch sent to the same public bodies with a different title and body' do
      expect(InfoRequestBatch.find_existing(info_request_batch.user,
                                            'Other title',
                                            'Other body',
                                            [first_body])).to be_nil
    end

    it 'should not return a batch sent to one of the same public bodies with the same title and body by
          a different user' do
      expect(InfoRequestBatch.find_existing(FactoryGirl.create(:user),
                                            info_request_batch.title,
                                            info_request_batch.body,
                                            [first_body])).to be_nil
    end

  end

  context "when creating a batch" do
    let(:first_public_body) { FactoryGirl.create(:public_body) }
    let(:second_public_body) { FactoryGirl.create(:public_body) }
    let(:info_request_batch) do
      FactoryGirl.create(
        :info_request_batch,
        :body => "Dear [Authority name],\nA message\nYours faithfully,\nRequester",
        :public_bodies => [first_public_body, second_public_body])
    end

    it 'should substitute authority name for the placeholder in each request' do
      unrequestable = info_request_batch.create_batch!
      [first_public_body, second_public_body].each do |public_body|
        request = info_request_batch.info_requests.detect do |info_request|
          info_request.public_body == public_body
        end
        expected = "Dear #{public_body.name},\nA message\nYours faithfully,\nRequester"
        expect(request.outgoing_messages.first.body).to eq(expected)
      end
    end

    it 'should send requests to requestable public bodies, and return a list of unrequestable ones' do
      allow(first_public_body).to receive(:is_requestable?).and_return(false)
      unrequestable = info_request_batch.create_batch!
      expect(unrequestable).to eq([first_public_body])
      expect(info_request_batch.info_requests.size).to eq(1)
      request = info_request_batch.info_requests.first
      expect(request.outgoing_messages.first.status).to eq('sent')
    end

    it 'should set the sent_at value of the info request batch' do
      info_request_batch.create_batch!
      expect(info_request_batch.sent_at).not_to be_nil
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
    let(:first_public_body) { FactoryGirl.create(:public_body) }
    let(:second_public_body) { FactoryGirl.create(:public_body) }
    let!(:info_request_batch) do
      FactoryGirl.create(
        :info_request_batch,
        :public_bodies => [first_public_body, second_public_body])
    end
    let!(:sent_batch) do
      FactoryGirl.create(
        :info_request_batch,
        :public_bodies => [first_public_body, second_public_body],
        :sent_at => Time.zone.now)
    end

    it 'should send requests and notifications for only unsent batch requests' do
      InfoRequestBatch.send_batches
      expect(ActionMailer::Base.deliveries.size).to eq(3)
      first_email = ActionMailer::Base.deliveries.first
      expect(first_email.to).to eq([first_public_body.request_email])
      expect(first_email.subject).to eq('Freedom of Information request - Example title')

      second_email = ActionMailer::Base.deliveries.second
      expect(second_email.to).to eq([second_public_body.request_email])
      expect(second_email.subject).to eq('Freedom of Information request - Example title')

      third_email = ActionMailer::Base.deliveries.third
      expect(third_email.to).to eq([info_request_batch.user.email])
      expect(third_email.subject).to eq('Your batch request "Example title" has been sent')
    end

  end

  describe "#from_draft" do
    let(:first_public_body) { FactoryGirl.create(:public_body) }
    let(:second_public_body) { FactoryGirl.create(:public_body) }
    let(:draft) do
      FactoryGirl.create(
        :draft_info_request_batch,
        :public_bodies => [first_public_body, second_public_body])
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

  describe "#example_request" do
    let(:first_public_body) { FactoryGirl.create(:public_body) }
    let(:second_public_body) { FactoryGirl.create(:public_body) }

    context "when the batch has an embargo duration" do
      let(:info_request_batch) do
        FactoryGirl.create(
          :info_request_batch,
          :public_bodies => [first_public_body, second_public_body],
          :embargo_duration => "3_months")
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
        info_request_batch.save
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
        FactoryGirl.create(
          :info_request_batch,
          :public_bodies => [first_public_body, second_public_body])
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
        info_request_batch.save
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

end
