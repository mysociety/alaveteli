require 'spec_helper'
require_dependency 'project/export/info_request'

RSpec.describe Project::Export::InfoRequest do
  include Rails.application.routes.url_helpers
  include LinkToHelper

  let(:project) { FactoryBot.build(:project) }
  let(:contributor) { FactoryBot.build(:user) }

  let(:public_body) { FactoryBot.build(:public_body) }
  let(:info_request) do
    FactoryBot.build(:info_request, public_body: public_body)
  end

  let(:instance) { described_class.new(project, info_request) }

  describe '#data' do
    subject(:data) { instance.data }

    shared_context 'with non-project classification' do
      before do
        info_request.described_state = 'successful'
      end
    end

    shared_context 'with project classification' do
      let(:url) do
        request_url(info_request, host: AlaveteliConfiguration.domain)
      end

      before do
        FactoryBot.create(
          :project_submission,
          :for_classification,
          project: project,
          info_request: info_request,
          user: contributor
        )
      end
    end

    shared_context 'with project extraction' do
      before do
        FactoryBot.create(
          :project_submission,
          :for_extraction,
          project: project,
          info_request: info_request,
          user: contributor
        )
      end
    end

    context 'when info request has been classified outside of projects' do
      include_context 'with non-project classification'

      it 'uses project owner as latest status contributor' do
        expect(data[:latest_status_contributor]).to eq project.owner.name
      end
    end

    context 'when info request has been classified' do
      include_context 'with project classification'

      it 'shows classification and contributor' do
        is_expected.to eq(
          request_url: url,
          request_title: info_request.title,
          public_body_name: public_body.name,
          request_owner: info_request.user.name,
          latest_status_contributor: contributor.name,
          status: info_request.described_state,
          dataset_contributor: nil
        )
      end
    end

    context 'when info request has been classified and extracted' do
      include_context 'with project classification'
      include_context 'with project extraction'

      it 'shows extracted values and contributor' do
        is_expected.to eq(
          :request_url => url,
          :request_title => info_request.title,
          :public_body_name => public_body.name,
          :request_owner => info_request.user.name,
          :latest_status_contributor => contributor.name,
          :status => info_request.described_state,
          :dataset_contributor => contributor.name,
          'Were there any errors?' => '1'
        )
      end
    end
  end
end
