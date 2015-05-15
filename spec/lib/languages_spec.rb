# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe LanguageNames do

    describe :get_language_name do

        it 'should return the name assigned to the language' do
            LanguageNames.get_language_name('en').should == 'English'
        end

        it 'should return the name assigned to the language when there is no specific location' do
            LanguageNames.get_language_name('pt_BR').should == 'Português'
        end

        it 'should return the name assigned to the language/location combination' do
            LanguageNames.get_language_name('zh_HK').should == '中文(香港)'
        end

    end

end
