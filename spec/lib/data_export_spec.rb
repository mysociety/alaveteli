require 'spec_helper'
require Rails.root.join('lib/data_export')

RSpec.describe DataExport do

  describe '.case_insensitive_user_censor' do
    subject { described_class.case_insensitive_user_censor(text, user) }
    let(:text) { "Yours faithfully, #{ user.name }" }
    let(:user) { FactoryBot.build(:user, name: 'A User') }

    it { is_expected.to eq 'Yours faithfully, <REQUESTER>' }

    context 'the user name contains asterisks' do
      let(:user) { FactoryBot.build(:user, name: 'A ** User') }

      it { is_expected.to eq 'Yours faithfully, <REQUESTER>' }
    end

    context 'the user name contains a bracket' do
      let(:user) { FactoryBot.build(:user, name: 'A (User') }

      it { is_expected.to eq 'Yours faithfully, <REQUESTER>' }
    end

  end

  describe ".exportable_requests" do

    let(:cut_off) { Date.today + 1 }

    it "includes eligible requests " do
      request = FactoryBot.create(:info_request)
      exportable = described_class.exportable_requests(cut_off)

      expect(exportable).to include(request)
    end

    it "does not include hidden requests" do
      hidden = FactoryBot.create(:info_request, :prominence => 'hidden')
      exportable = described_class.exportable_requests(cut_off)

      expect(exportable).to_not include(hidden)
    end

    it "does not include requests created after the cut_off date" do
      request = FactoryBot.create(:info_request)
      exportable = described_class.exportable_requests(Date.today)

      expect(exportable).to_not include(request)
    end

    it "does not include embargoed requests" do
      embargoed = FactoryBot.create(:embargoed_request)
      exportable = described_class.exportable_requests(cut_off)

      expect(exportable).to_not include(embargoed)
    end

  end

  describe ".exportable_incoming_messages" do

    let(:cut_off) { Date.today + 1 }

    it "includes eligible messages" do
      incoming = FactoryBot.create(:incoming_message)
      exportable = described_class.exportable_incoming_messages(cut_off)

      expect(exportable).to include(incoming)
    end

    it "does not include hidden messages" do
      hidden = FactoryBot.create(:incoming_message, :prominence => 'hidden')
      exportable = described_class.exportable_incoming_messages(cut_off)

      expect(exportable).to_not include(hidden)
    end

    it "does not include messages created after the cut_off date" do
      incoming = FactoryBot.create(:incoming_message)
      exportable = described_class.exportable_incoming_messages(Date.today)

      expect(exportable).to_not include(incoming)
    end

    it "does not include messages belonging to hidden requests" do
      hidden_request = FactoryBot.create(:info_request,
                                         :prominence => 'hidden')
      message = FactoryBot.create(:incoming_message,
                                  :info_request => hidden_request)

      exportable = described_class.exportable_incoming_messages(cut_off)
      expect(exportable).to_not include(message)
    end

    it "does not include messages belonging to embargoed requests" do
      embargoed = FactoryBot.create(:embargoed_request)
      message = FactoryBot.create(:incoming_message,
                                  :info_request => embargoed)

      exportable = described_class.exportable_incoming_messages(cut_off)
      expect(exportable).to_not include(message)
    end

  end

  describe ".exportable_outgoing_messages" do

    let(:cut_off) { Date.today + 1 }

    it "includes eligible messages" do
      outgoing = FactoryBot.create(:initial_request)
      exportable = described_class.exportable_outgoing_messages(cut_off)

      expect(exportable).to include(outgoing)
    end

    it "does not include hidden messages" do
      hidden = FactoryBot.create(:initial_request, :prominence => 'hidden')
      exportable = described_class.exportable_outgoing_messages(cut_off)

      expect(exportable).to_not include(hidden)
    end

    it "does not include messages created after the cut_off date" do
      outgoing = FactoryBot.create(:initial_request)
      exportable = described_class.exportable_outgoing_messages(Date.today)

      expect(exportable).to_not include(outgoing)
    end

    it "does not include messages belonging to hidden requests" do
      hidden_request = FactoryBot.create(:info_request,
                                        :prominence => 'hidden')
      message = FactoryBot.create(:initial_request,
                                  :info_request => hidden_request)

      exportable = described_class.exportable_outgoing_messages(cut_off)
      expect(exportable).to_not include(message)
    end

    it "does not include messages belonging to embargoed requests" do
      embargoed = FactoryBot.create(:embargoed_request)
      message = FactoryBot.create(:initial_request,
                                  :info_request => embargoed)

      exportable = described_class.exportable_outgoing_messages(cut_off)
      expect(exportable).to_not include(message)
    end

  end

  describe ".exportable_foi_attachments" do

    let(:cut_off) { Date.today + 1 }

    it "includes eligible attachments" do
      incoming = FactoryBot.create(:incoming_message)
      attachment = FactoryBot.create(:html_attachment,
                                     :incoming_message => incoming)
      exportable = described_class.exportable_foi_attachments(cut_off)

      expect(exportable).to include(attachment)
    end

    it "does not include attachments of hidden messages" do
      incoming = FactoryBot.create(:incoming_message, :prominence => 'hidden')
      attachment = FactoryBot.create(:html_attachment,
                                     :incoming_message => incoming)
      exportable = described_class.exportable_foi_attachments(cut_off)

      expect(exportable).to_not include(attachment)
    end

    it "does not include attachments of messages created after the cut_off" do
      incoming = FactoryBot.create(:incoming_message)
      attachment = FactoryBot.create(:html_attachment,
                                     :incoming_message => incoming)
      exportable = described_class.exportable_foi_attachments(Date.today)

      expect(exportable).to_not include(attachment)
    end

    it "does not include attachments of messages belonging to hidden requests" do
      hidden_request = FactoryBot.create(:info_request,
                                         :prominence => 'hidden')
      incoming = FactoryBot.create(:incoming_message,
                                   :info_request => hidden_request)
      attachment = FactoryBot.create(:html_attachment,
                                     :incoming_message => incoming)

      exportable = described_class.exportable_foi_attachments(cut_off)
      expect(exportable).to_not include(attachment)
    end

    it "does not include attachments related to embargoed requests" do
      embargoed = FactoryBot.create(:embargoed_request)
      incoming = FactoryBot.create(:incoming_message,
                                   :info_request => embargoed)
      attachment = FactoryBot.create(:html_attachment,
                                     :incoming_message => incoming)

      exportable = described_class.exportable_foi_attachments(cut_off)
      expect(exportable).to_not include(attachment)
    end

  end

end
