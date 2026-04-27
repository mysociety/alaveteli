require 'spec_helper'

RSpec.describe ActiveStorage::Blobs::RedirectController, type: :request do
  describe 'GET show' do
    it 'returns 404 for an unattached blob' do
      blob = ActiveStorage::Blob.create_and_upload!(
        io: StringIO.new('test'), filename: 'test.txt',
        content_type: 'text/plain'
      )

      get rails_service_blob_path(blob.signed_id, 'test.txt')
      expect(response).to have_http_status(:not_found)
    end
  end
end
