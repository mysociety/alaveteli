require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HealthChecksHelper do
    include HealthChecksHelper

    describe :check_status do

        it 'warns that the check is failing' do
            check = double(:message => 'Failed', :ok? => false)
            expect(check_status(check)).to include('red')
        end

    end

end
