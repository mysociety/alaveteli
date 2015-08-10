# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe AttachmentToHTML::View do

  let(:adapter) do
    OpenStruct.new(
      :body => '<p>hello</p>',
      :title => 'An attachment.txt',
    :success? => true)
  end

  let(:view) { AttachmentToHTML::View.new(adapter) }

  let(:default_template) do
    "#{ Rails.root }/lib/attachment_to_html/template.html.erb"
  end

  describe '.template' do

    after(:each) do
      AttachmentToHTML::View.template = nil
    end

    it 'has a default template location' do
      expect(AttachmentToHTML::View.template).to eq(default_template)
    end

  end

  describe '.template=' do

    after(:each) do
      AttachmentToHTML::View.template = nil
    end

    it 'allows a global template to be set' do
      template = file_fixture_name('attachment_to_html/alternative_template.html.erb')
      AttachmentToHTML::View.template = template
      expect(AttachmentToHTML::View.template).to eq(template)
    end

  end

  describe :new do

    it 'sets the title on initialization' do
      expect(view.title).to eq(adapter.title)
    end

    it 'sets the body on initialization' do
      expect(view.body).to eq(adapter.body)
    end

    it 'sets a default template if none is specified' do
      expect(view.template).to eq(default_template)
    end

    it 'allows a template to be set through an option' do
      template = file_fixture_name('attachment_to_html/alternative_template.html.erb')
      opts = { :template => template }
      view = AttachmentToHTML::View.new(adapter, opts)
      expect(view.template).to eq(template)
    end

  end

  describe :title= do

    it 'allows the title to be set' do
      view.title = adapter.title
      expect(view.title).to eq(adapter.title)
    end

  end

  describe :body= do

    it 'allows the body to be set' do
      view.body = adapter.body
      expect(view.body).to eq(adapter.body)
    end

  end

  describe :template= do

    it 'allows the template to be set' do
      template = file_fixture_name('attachment_to_html/alternative_template.html.erb')
      view.template = template
      expect(view.template).to eq(template)
    end

  end

  describe :wrapper do

    it 'is set to wrapper by default' do
      expect(view.wrapper).to eq('wrapper')
    end

  end

  describe :wrapper= do

    it 'allows the wrapper div to be customised' do
      view.wrapper = 'wrap'
      expect(view.wrapper).to eq('wrap')
    end

  end

  # Need to remove all whitespace to assert equal because
  # ERB adds additional indentation after ERB tags
  describe :render do

    it 'renders the contents in to the template' do
      view.wrapper = 'wrap'
      expected = <<-HTML
      <!DOCTYPE html>
      <html>
      <head>
      <meta charset="UTF-8">
      <title>An attachment.txt</title>
      </head>
      <body>
      <div id="wrap">
      <div id="view-html-content">
      <p>hello</p>
      </div>
      </div>
      </body>
      </html>
      HTML

      expect(view.render.gsub(/\s+/, '')).to eq(expected.gsub(/\s+/, ''))
    end

    it 'allows the dynamic injection of content' do
      content = %Q(<meta charset="utf-8">)
      result = view.render { inject_content(:head_suffix) { content } }
      expect(result).to include(content)
    end

  end

end
