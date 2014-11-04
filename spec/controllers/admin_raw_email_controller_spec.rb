require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe AdminRawEmailController do

    describe :show do

        it 'renders the show template' do
            raw_email = FactoryGirl.create(:incoming_message).raw_email
            get :show, :id => raw_email.id
        end

    end

end
