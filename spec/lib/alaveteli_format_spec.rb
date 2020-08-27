require 'spec_helper'

describe Alaveteli::Format do
  describe '.simplify_url_part' do
    it 'transliterates characters into ASCII' do
      default_name = 'body'

      examples = [
        ['Državno sodišče', 'drzavno_sodisce'],
        ['Реактор Большой Мощности Канальный', 'rieaktor_bolshoi_moshchnosti_kanalnyi'],
        ['Prefeitura de Curuçá - PA ', 'prefeitura_de_curuca_pa'],
        ['Prefeitura de Curuá - PA ', 'prefeitura_de_curua_pa'],
        ['Prefeitura de Pirajuí - SP', 'prefeitura_de_pirajui_sp'],
        ['Siméon', 'simeon'],
        ['Nordic æøå', 'nordic_aeoa'],
        ['بلدية سيدي بو سعيد', 'bldy_sydy_bw_syd'],
        ['محمود', 'mhmwd'],
      ]
      examples.each do |name, expected_url_name|
        url_name = described_class.simplify_url_part(name, default_name)
        expect(url_name).to eq expected_url_name
      end
    end
  end
end
