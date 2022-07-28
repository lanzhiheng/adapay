# frozen_string_literal: true

RSpec.describe Adapay do
  it 'has a version number' do
    expect(Adapay::VERSION).not_to be nil
  end

  it 'version' do
    expect(Adapay.sdk_version).to eq('ruby_1.0.0')
  end

  # 验证签名算法
  it 'verify content from adapay service' do
    key_content = File.read('./spec/fixtures/adapay_platform_private_key.pem')
    private_key = OpenSSL::PKey::RSA.new(key_content)
    string = 'Hello Ruby'
    sign_string = Base64.strict_encode64(private_key.sign('SHA1', string))
    expect(Adapay.verify(sign_string, string)).to eq(true)
  end

  # 签名算法
  it 'sign content for sending request to adapay service' do
    string = 'Hello Ruby'
    sign_string = Adapay.sign(string)
    expect(Adapay.merchant_verify(sign_string, string))
  end
end
