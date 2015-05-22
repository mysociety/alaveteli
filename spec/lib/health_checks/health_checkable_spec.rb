# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe HealthChecks::HealthCheckable do

    before(:each) do
        class MockCheck
            include HealthChecks::HealthCheckable
        end
        @subject = MockCheck.new
    end

    describe :initialize do

        it 'allows a custom failure message to be set' do
            @subject = MockCheck.new(:failure_message => 'F')
            expect(@subject.failure_message).to eq('F')
        end

        it 'allows a custom success message to be set' do
            @subject = MockCheck.new(:success_message => 'S')
            expect(@subject.success_message).to eq('S')
        end

    end

    describe :name do

        it 'returns the name of the check' do
            expect(@subject.name).to eq('MockCheck')
        end

    end

    describe :ok? do

        it 'is intended to be overridden by the includer' do
            expect{ @subject.ok? }.to raise_error(NotImplementedError)
        end

    end

    describe :failure_message do

        it 'returns a default message if one has not been set' do
            expect(@subject.failure_message).to eq('Failed')
        end

    end

    describe :failure_message= do

        it 'allows a custom failure message to be set' do
            @subject.failure_message = 'F'
            expect(@subject.failure_message).to eq('F')
        end

    end

    describe :success_message do

        it 'returns a default message if one has not been set' do
            expect(@subject.success_message).to eq('Success')
        end

    end

    describe :success_message= do

        it 'allows a custom success message to be set' do
            @subject.success_message = 'S'
            expect(@subject.success_message).to eq('S')
        end

    end

    describe :message do

        context 'if the check succeeds' do

            before(:each) do
                @subject.stub(:ok? => true)
            end

            it 'returns the default success message' do
                expect(@subject.message).to eq('Success')
            end

            it 'returns a custom success message if one has been set' do
                @subject.success_message = 'Custom Success'
                expect(@subject.message).to eq('Custom Success')
            end

        end

        context 'if the check fails' do

            before(:each) do
                @subject.stub(:ok? => false)
            end

            it 'returns the default failure message' do
                expect(@subject.message).to eq('Failed')
            end

            it 'returns a custom failure message if one has been set' do
                @subject.failure_message = 'Custom Failed'
                expect(@subject.message).to eq('Custom Failed')
            end

        end

    end

end
