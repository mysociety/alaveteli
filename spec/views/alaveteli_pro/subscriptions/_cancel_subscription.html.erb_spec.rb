# -*- encoding : utf-8 -*-
require File.expand_path(File.join('..', '..', '..', '..', 'spec_helper'), __FILE__)

describe 'alaveteli_pro/subscriptions/_cancel_subscription' do

  def render_view
    render partial: 'alaveteli_pro/subscriptions/cancel_subscription',
           locals: { subscription: subscription }
  end

  context 'with an active subscription' do

    let(:subscription) do
      double(id: 'sub_BWb9jBSSO0nafs',
             cancel_at_period_end: false,
             current_period_end: 1509882971)
    end

    it 'sets the section heading' do
      render_view
      expect(rendered).to have_content('Cancel your subscription')
    end

    it 'adds an .active class to the .cancel-subscription__message div' do
      render_view
      expect(rendered).to have_css('div.cancel-subscription__message.active')
    end

    it 'displays the what happens if you cancel' do
      render_view
      expect(rendered).to have_content(<<-EOF.squish)
      When you cancel your account:
      EOF
    end

    it 'displays a link to allow the user to cancel' do
      render_view
      expect(rendered).
        to have_link(text: 'I understand and still want to cancel',
                     href: subscription_path(subscription.id) )
    end

  end

  context 'with a cancelled subscription' do

    let(:subscription) do
      double(id: 'sub_BWb9jBSSO0nafs',
             cancel_at_period_end: true,
             current_period_end: 1509882971)
    end

    it 'sets the section heading' do
      render_view
      expect(rendered).to have_content('Your subscription has been cancelled,')
    end

    it 'adds a .cancelled class to the .cancel-subscription__message div' do
      render_view
      expect(rendered).to have_css('div.cancel-subscription__message.cancelled')
    end

    it 'displays what will happen at the end of the billing period' do
      render_view
      expect(rendered).to have_content(<<-EOF.squish)
      When the current billing period ends:
      EOF
    end

    it 'does not show a cancellation link' do
      render_view
      expect(rendered).not_to have_link(text: 'Cancel your subscription')
    end

  end

end
