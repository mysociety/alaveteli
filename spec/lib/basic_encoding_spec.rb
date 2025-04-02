require 'spec_helper'

def bytes_to_binary_string( bytes, claimed_encoding = nil )
  claimed_encoding ||= 'ASCII-8BIT'
  bytes_string = bytes.pack('c*')
  bytes_string.force_encoding claimed_encoding
end

random_string = bytes_to_binary_string [ 0x0f, 0x58, 0x1c, 0x8f, 0xa4, 0xcf,
                                         0xf6, 0x8c, 0x9d, 0xa7, 0x06, 0xd9,
                                         0xf7, 0x90, 0x6c, 0x6f]

# "DASH – DASH" <- en dash
windows_1252_string = bytes_to_binary_string [ 0x44, 0x41, 0x53, 0x48, 0x20,
                                               0x96, 0x20, 0x44, 0x41, 0x53,
                                               0x48 ]

# "DONG ₫ DONG" <- currency symbol
windows_1258_string = bytes_to_binary_string [ 0x44, 0x4f, 0x4e, 0x47, 0x20,
                                               0xFE, 0x20, 0x44, 0x4f, 0x4e,
                                               0x47 ]
# 0x92 is an invalid ISO-2022-JP byte
# should probably be `’` in Windows-1250 - Windows-1257
iso_2022_jp_string = bytes_to_binary_string [ 0xE7, 0x84, 0xA1, 0xE5, 0x8A,
                                              0xB9, 0xE3, 0x81, 0xA7, 0xE3,
                                              0x81, 0x99, 0x92 ]

# It's a shame this example is so long, but if we don't take enough it
# gets misinterpreted as Shift_JIS

gb_18030_bytes = [ 0xb9, 0xf3, 0xb9, 0xab, 0xcb, 0xbe, 0xb8, 0xba, 0xd4, 0xf0,
                   0xc8, 0xcb, 0x28, 0xbe, 0xad, 0xc0, 0xed, 0x2f, 0xb2, 0xc6,
                   0xce, 0xf1, 0x29, 0xc4, 0xfa, 0xba, 0xc3, 0xa3, 0xba, 0x0d,
                   0x0a, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20,
                   0x20, 0x20, 0x20, 0xb1, 0xbe, 0xb9, 0xab, 0xcb, 0xbe, 0xd4,
                   0xda, 0x31, 0x39, 0x39, 0x37, 0xc4, 0xea, 0xb3, 0xc9, 0xc1,
                   0xa2, 0xb9, 0xfa, 0xbc, 0xd2, 0xb9, 0xa4, 0xc9, 0xcc, 0xd7,
                   0xa2, 0xb2, 0xe1, 0x2e, 0xca, 0xb5, 0xc1, 0xa6, 0xd0, 0xdb,
                   0xba, 0xf1, 0xa1, 0xa3, 0xd3, 0xd0, 0xb6, 0xc0, 0xc1, 0xa2,
                   0xcb, 0xb0, 0xce, 0xf1, 0x0d, 0x0a, 0x20, 0x20, 0x20, 0x20,
                   0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xd7, 0xa8, 0xd2, 0xb5,
                   0xc8, 0xcb, 0xd4, 0xb1, 0x3b, 0xd4, 0xda, 0xc8, 0xab, 0xb9,
                   0xfa, 0xb8, 0xf7, 0xb3, 0xc7, 0xca, 0xd0, 0xc9, 0xe8, 0xc1,
                   0xa2, 0xb7, 0xd6, 0xb9, 0xab, 0xcb, 0xbe, 0xa3, 0xa8, 0xd5,
                   0xe3, 0xbd, 0xad, 0xa1, 0xa2, 0xc9, 0xcf, 0xba, 0xa3, 0xa1,
                   0xa2, 0xb9, 0xe3, 0xd6, 0xdd, 0xa1, 0xa2, 0xbd, 0xad, 0xcb,
                   0xd5, 0xb5, 0xc8, 0x0d, 0x0a, 0x20, 0x20, 0x20, 0x20, 0x20,
                   0x20, 0x20, 0x20, 0x20, 0x20, 0xb5, 0xd8, 0xb7, 0xbd, 0xa3,
                   0xa9, 0xd2, 0xf2, 0xbd, 0xf8, 0xcf, 0xee, 0xbd, 0xcf, 0xb6,
                   0xe0, 0xcf, 0xd6, 0xcd, 0xea, 0xb3, 0xc9, 0xb2, 0xbb, 0xc1,
                   0xcb, 0xc3, 0xbf, 0xd4, 0xc2, 0xcf, 0xfa, 0xca, 0xdb, 0xb6,
                   0xee, 0xb6, 0xc8, 0xa1, 0xa3, 0xc3, 0xbf, 0xd4, 0xc2, 0xd3,
                   0xd0, 0xd2, 0xbb, 0xb2, 0xbf, 0xb7, 0xd6, 0x0d, 0x0a, 0x20,
                   0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xd4,
                   0xf6, 0xd6, 0xb5, 0xb6, 0x90, 0xa3, 0xa8, 0x36, 0x2d, 0x37,
                   0x25, 0xd7, 0xf3, 0xd3, 0xd2, 0x29, 0xba, 0xcd, 0xc6, 0xd5,
                   0xc6, 0xb1, 0xa3, 0xa8, 0x30, 0x2e, 0x35, 0x25, 0x2d, 0x32,
                   0x25, 0x20, 0xd7, 0xf3, 0xd3, 0xd2, 0xa3, 0xa9, 0xd3, 0xc5,
                   0xbb, 0xdd, 0xb4, 0xfa, 0xbf, 0xaa, 0xbb, 0xf2, 0xba, 0xcf,
                   0xd7, 0xf7, 0xa3, 0xac, 0x0d, 0x0a, 0x20, 0x20, 0x20, 0x20,
                   0x20, 0x20, 0x20, 0x20, 0x20, 0x20, 0xb5, 0xe3, 0xca, 0xfd,
                   0xbd, 0xcf, 0xb5, 0xcd, 0xa1, 0xa3, 0xb4, 0xfa, 0xc0, 0xed,
                   0xb7, 0xb6, 0xce, 0xa7, 0xc8, 0xe7, 0xcf, 0xc2, 0xa3, 0xba,
                   0x0d, 0x0a ]

gb_18030_spam_string = bytes_to_binary_string gb_18030_bytes

RSpec.describe '#normalize_line_endings' do
  it 'converts Windows line endings (CRLF) to Unix line endings (LF)' do
    windows_text = "Line 1\r\nLine 2\r\nLine 3"
    expected_unix_text = "Line 1\nLine 2\nLine 3"

    expect(normalize_line_endings(windows_text)).to eq(expected_unix_text)
  end

  it 'converts old Mac line endings (CR) to Unix line endings (LF)' do
    old_mac_text = "Line 1\rLine 2\rLine 3"
    expected_unix_text = "Line 1\nLine 2\nLine 3"

    expect(normalize_line_endings(old_mac_text)).to eq(expected_unix_text)
  end

  it 'leaves Unix line endings unchanged' do
    unix_text = "Line 1\nLine 2\nLine 3"

    expect(normalize_line_endings(unix_text)).to eq(unix_text)
  end

  it 'handles mixed line endings' do
    mixed_text = "Line 1\nLine 2\r\nLine 3\rLine 4"
    expected_unix_text = "Line 1\nLine 2\nLine 3\nLine 4"

    expect(normalize_line_endings(mixed_text)).to eq(expected_unix_text)
  end
end

RSpec.describe "normalize_string_to_utf8" do
  describe "when passed uniterpretable character data" do
    it "should reject it as invalid" do
      expect {
        normalize_string_to_utf8 random_string
      }.to raise_error(EncodingNormalizationError)

      expect {
        normalize_string_to_utf8 random_string, 'UTF-8'
      }.to raise_error(EncodingNormalizationError)
    end
  end

  describe "when passed unlabelled Windows 1252 data" do
    it "should correctly convert it to UTF-8" do
      normalized = normalize_string_to_utf8 windows_1252_string

      expect(normalized).to eq("DASH – DASH")
    end
  end

  describe "when passed suggested Windows 1258 data" do
    it "should raise EncodingNormalizationError" do
      expect {
        normalize_string_to_utf8 windows_1258_string, 'windows-1258'
      }.to raise_error(
        EncodingNormalizationError,
        'code converter not found (Windows-1258 to UTF-8)'
      )
    end
  end

  describe "when passed suggested ISO-2022-JP data" do
    it "should raise EncodingNormalizationError" do
      expect {
        normalize_string_to_utf8 iso_2022_jp_string, 'iso-2022-jp'
      }.to raise_error(
        EncodingNormalizationError,
        '"\xE7" on ISO-2022-JP'
      )
    end
  end

  describe "when passed GB 18030 data" do
    it "should correctly convert it to UTF-8 if unlabelled" do
      normalized = normalize_string_to_utf8 gb_18030_spam_string

      expect(normalized).to start_with("贵公司负责人")
    end
  end
end

RSpec.describe "convert_string_to_utf8_or_binary" do
  describe "when passed uninterpretable character data" do
    it "should return it as a binary string" do
      converted = convert_string_to_utf8_or_binary random_string
      expect(converted).to eq(random_string)
      expect(converted.encoding.to_s).to eq('ASCII-8BIT')

      converted = convert_string_to_utf8_or_binary random_string,'UTF-8'
      expect(converted).to eq(random_string)
      expect(converted.encoding.to_s).to eq('ASCII-8BIT')
    end
  end

  describe "when passed unlabelled Windows 1252 data" do
    it "should correctly convert it to UTF-8" do
      converted = convert_string_to_utf8_or_binary windows_1252_string

      expect(converted).to eq("DASH – DASH")
      expect(converted.encoding.to_s).to eq('UTF-8')
    end
  end

  describe "when passed suggested Windows 1258 data" do
    it "should return data as ASCII-8BIT" do
      converted = convert_string_to_utf8_or_binary(
        windows_1258_string, 'windows-1258'
      )

      expect(converted).to eq("DONG \xFE DONG".force_encoding('ASCII-8BIT'))
      expect(converted.encoding.to_s).to eq('ASCII-8BIT')
    end
  end

  describe "when passed suggested ISO-2022-JP data" do
    it "should return data as ASCII-8BIT" do
      converted = convert_string_to_utf8_or_binary(
        iso_2022_jp_string, 'iso-2022-jp'
      )

      expect(converted).to eq("無効です\x92".force_encoding('ASCII-8BIT'))
      expect(converted.encoding.to_s).to eq('ASCII-8BIT')
    end
  end

  describe "when passed GB 18030 data" do
    it "should correctly convert it to UTF-8 if unlabelled" do
      converted = convert_string_to_utf8_or_binary gb_18030_spam_string

      expect(converted).to start_with("贵公司负责人")
      expect(converted.encoding.to_s).to eq('UTF-8')
    end
  end
end

RSpec.describe "convert_string_to_utf8" do
  describe "when passed uninterpretable character data" do
    it "should return it as a valid utf8 string with non-utf8 characters removed
            and mark it as scrubbed" do
      converted = convert_string_to_utf8 random_string

      expect(converted.string.encoding.to_s).to eq('UTF-8')
      expect(converted.string.valid_encoding?).to eq(true)
      expect(converted.scrubbed?).to eq(true)

      converted = convert_string_to_utf8 random_string,'UTF-8'

      expect(converted.string.encoding.to_s).to eq('UTF-8')
      expect(converted.string.valid_encoding?).to eq(true)
      expect(converted.scrubbed?).to eq(true)
    end
  end

  describe "when passed unlabelled Windows 1252 data" do
    it "should correctly convert it to UTF-8" do
      converted = convert_string_to_utf8 windows_1252_string

      expect(converted.string).to eq("DASH – DASH")

      expect(converted.string.encoding.to_s).to eq('UTF-8')
      expect(converted.scrubbed?).to eq(false)
    end
  end

  describe "when passed suggested Windows 1258 data" do
    it "should return scrubbed UTF-8 string" do
      converted = convert_string_to_utf8(windows_1258_string, 'windows-1258')

      expect(converted.string).to eq("DONG  DONG")
      expect(converted.string.encoding.to_s).to eq('UTF-8')
      expect(converted.scrubbed?).to eq(true)
    end
  end

  describe "when passed suggested ISO-2022-JP data" do
    it "should return scrubbed UTF-8 string" do
      converted = convert_string_to_utf8(iso_2022_jp_string, 'iso-2022-jp')

      expect(converted.string).to eq("無効です")
      expect(converted.string.encoding.to_s).to eq('UTF-8')
      expect(converted.scrubbed?).to eq(true)
    end
  end

  describe "when passed GB 18030 data" do
    it "should correctly convert it to UTF-8 if unlabelled" do
      converted = convert_string_to_utf8 gb_18030_spam_string

      expect(converted.string).to start_with("贵公司负责人")
      expect(converted.string.encoding.to_s).to eq('UTF-8')
      expect(converted.scrubbed?).to eq(false)
    end
  end
end
