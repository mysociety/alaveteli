require 'spec_helper'

describe 'request/sidebar' do
  def render_view
    render partial: self.class.top_level_description,
           locals: stub_locals
  end

  let(:info_request) { FactoryBot.build(:info_request) }
  let(:similar_requests) { double.as_null_object }
  let(:similar_more) { double.as_null_object }

  let(:stub_locals) do
    { info_request: info_request,
      similar_requests: similar_requests,
      similar_more: similar_more }
  end

  it 'renders the new request CTA' do
    render_view
    expect(rendered).to render_template(partial: 'general/_new_request')
  end

  it 'renders the pro upsell' do
    render_view
    expect(rendered).to render_template(partial: '_sidebar_pro_upsell')
  end

  context 'when the user can create_embargo', feature: :alaveteli_pro do
    before do
      ability = Object.new.extend(CanCan::Ability)
      ability.can :create_embargo, info_request
      allow(controller).to receive(:current_ability).and_return(ability)
      allow(view).to receive(:current_user).and_return(info_request.user)
    end

    it 'renders the embargo_form' do
      render_view
      partial = 'alaveteli_pro/info_requests/_embargo_form'
      expect(rendered).to render_template(partial: partial)
    end
  end

  context 'when the user cannot create_embargo', feature: :alaveteli_pro do
    before do
      ability = Object.new.extend(CanCan::Ability)
      ability.cannot :create_embargo, info_request
      allow(controller).to receive(:current_ability).and_return(ability)
      allow(view).to receive(:current_user).and_return(info_request.user)
    end

    it 'does not render the embargo_form' do
      render_view
      partial = 'alaveteli_pro/info_requests/_embargo_form'
      expect(rendered).not_to render_template(partial: partial)
    end
  end

  context 'when the request is attention_requested' do
    let(:info_request) do
      stubs = { prominence: double.as_null_object,
                attention_requested: true }
      double('InfoRequest', stubs).as_null_object
    end

    it 'renders attention_requested' do
      render_view
      expect(rendered).to render_template(partial: '_attention_requested')
    end
  end

  context 'when the request is not attention_requested' do
    let(:info_request) do
      stubs = { prominence: double.as_null_object,
                attention_requested: false }
      double('InfoRequest', stubs).as_null_object
    end

    it 'does not render attention_requested' do
      render_view
      expect(rendered).not_to render_template(partial: '_attention_requested')
    end
  end

  it 'renders act links' do
    render_view
    expect(rendered).to render_template(partial: 'request/_act')
  end

  it 'renders next_actions' do
    render_view
    expect(rendered).to render_template(partial: 'request/_next_actions')
  end

  it 'renders batch' do
    render_view
    expect(rendered).to render_template(partial: 'request/_batch')
  end

  context 'when there are similar requests' do
    let(:similar_requests) { double(any?: true).as_null_object }

    it 'renders the similar requests' do
      render_view
      expect(rendered).to render_template(partial: 'request/_similar')
    end
  end

  context 'when there are no similar requests' do
    let(:similar_requests) { double(any?: false) }

    it 'does not renders the similar requests' do
      render_view
      expect(rendered).not_to render_template(partial: 'request/_similar')
    end
  end

  it 'renders the copyright notice' do
    render_view
    expect(rendered).to match(/Are you the owner of any commercial copyright/)
  end
end
