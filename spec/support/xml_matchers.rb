require 'nokogiri'

RSpec::Matchers.define :have_xml do |xpath, text|
  match do |body|
    doc = Nokogiri::XML(body)
    nodes = doc.xpath(xpath)
    expect(nodes.empty?).to eq false
    if text
      nodes.each do |node|
        expect(node.content).to eq text
      end
    end
    true
  end

  failure_message do |body|
    "expected to find xml tag #{xpath} in:\n#{body}"
  end

  failure_message_when_negated do |_response|
    "expected not to find xml tag #{xpath} in:\n#{body}"
  end

  description do
    "have xml tag #{xpath}"
  end
end
