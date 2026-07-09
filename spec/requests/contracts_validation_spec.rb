# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "API Parameter Contracts Validation", type: :request do
  it "rejects invalid parameters for rate_limit endpoint" do
    get "/api/v1/rate_limit", params: { ip: "" }
    expect(response).to have_http_status(:unprocessable_entity)
    expect(JSON.parse(response.body)['error']).to eq('Invalid parameters')
  end

  it "rejects non-integer limit parameters for bulk_export endpoint" do
    get "/api/v1/bulk_export", params: { limit: "invalid" }
    expect(response).to have_http_status(:unprocessable_entity)
  end
end
