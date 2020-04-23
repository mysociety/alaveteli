require 'spec_helper'

spec_meta = {
  type: :controller,
  feature: :projects
}

RSpec.describe Projects::BaseController, spec_meta do
  controller(Projects::BaseController) do
    def index
      head :index
    end
  end

  describe 'GET index' do
    context 'when projects are enabled' do
      it 'sets in_pro_area' do
        get :index
        expect(assigns(:in_pro_area)).to eq(true)
      end
    end

    context 'when projects are disabled' do
      it 'raises an ActiveRecord::RecordNotFound error' do
        expect {
          with_feature_disabled(:projects) do
            get :index
          end
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
