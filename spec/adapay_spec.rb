# frozen_string_literal: true

RSpec.describe Adapay do
  it 'has a version number' do
    expect(Adapay::VERSION).not_to be nil
  end

  it 'version' do
    expect(Adapay.sdk_version).to eq('ruby_1.0.1')
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

  describe 'build_request_info' do
    let(:test_url) { 'https://api.adapay.tech/v1/payments' }
    let(:test_params) do
      {
        app_id: 'adapay_id',
        order_no: 'test_order_001',
        pay_amt: '100.00',
        pay_channel: 'alipay'
      }
    end

    before do
      allow(Adapay).to receive(:sign).and_return('mocked_signature')
    end

    context 'for POST requests' do
      it 'builds correct headers with content-type and signature' do
        result = Adapay.build_request_info('post', test_url, test_params)

        expect(result).to include(
          'Content-type' => 'application/json',
          signature: 'mocked_signature',
          authorization: 'adapay_key',
          sdk_version: 'ruby_1.0.1'
        )
      end

      it 'signs the correct plain text for POST' do
        expected_plain_text = test_url + test_params.to_json
        expect(Adapay).to receive(:sign).with(expected_plain_text).and_return('signature')

        Adapay.build_request_info('post', test_url, test_params)
      end

      it 'handles uppercase POST method' do
        result = Adapay.build_request_info('POST', test_url, test_params)

        expect(result).to include(
          'Content-type' => 'application/json',
          signature: 'mocked_signature'
        )
      end
    end

    context 'for GET requests' do
      it 'builds correct headers with signature but no content-type' do
        result = Adapay.build_request_info('get', test_url, test_params)

        expect(result).to include(
          signature: 'mocked_signature',
          authorization: 'adapay_key',
          sdk_version: 'ruby_1.0.1'
        )
        expect(result).not_to have_key('Content-type')
      end

      it 'signs the correct plain text for GET' do
        expected_plain_text = test_url + Adapay.send(:get_original_str, test_params)
        expect(Adapay).to receive(:sign).with(expected_plain_text).and_return('signature')

        Adapay.build_request_info('get', test_url, test_params)
      end

      it 'handles uppercase GET method' do
        result = Adapay.build_request_info('GET', test_url, test_params)

        expect(result).to include(
          signature: 'mocked_signature'
        )
        expect(result).not_to have_key('Content-type')
      end
    end

    context 'for other HTTP methods' do
      it 'treats PUT like GET' do
        result = Adapay.build_request_info('put', test_url, test_params)

        expect(result).to include(
          signature: 'mocked_signature'
        )
        expect(result).not_to have_key('Content-type')
      end

      it 'treats DELETE like GET' do
        result = Adapay.build_request_info('delete', test_url, test_params)

        expect(result).to include(
          signature: 'mocked_signature'
        )
        expect(result).not_to have_key('Content-type')
      end
    end

    context 'with backup app_id' do
      let(:backup_params) do
        {
          app_id: 'adapay_backup_id',
          order_no: 'test_order_001',
          pay_amt: '100.00'
        }
      end

      it 'uses backup app key for authentication' do
        result = Adapay.build_request_info('post', test_url, backup_params)

        expect(result).to include(
          authorization: 'adapay_backup_key'
        )
      end
    end

    context 'parameter validation' do
      it 'handles empty parameters' do
        empty_params = { app_id: 'adapay_id' }
        result = Adapay.build_request_info('get', test_url, empty_params)

        expect(result).to include(
          signature: 'mocked_signature',
          authorization: 'adapay_key'
        )
      end

      it 'handles parameters with hash values' do
        complex_params = {
          app_id: 'adapay_id',
          order_no: 'test_order_001',
          expend: {
            open_id: 'openid123',
            user_name: 'test_user'
          }
        }

        result = Adapay.build_request_info('post', test_url, complex_params)

        expect(result).to include(
          'Content-type' => 'application/json',
          signature: 'mocked_signature'
        )
      end
    end

    context 'signature integration' do
      it 'actually calls the sign method with correct content' do
        allow(Adapay).to receive(:sign).and_call_original

        result = Adapay.build_request_info('post', test_url, test_params)
        expect(result[:signature]).to be_a(String)
      end
    end
  end

  describe 'CorpMember' do
    let(:required_params) do
      {
        member_id: 'member_test_001',
        order_no: 'order_test_001',
        name: 'Test Company',
        prov_code: '310000',
        city_code: '310100',
        district_code: '310101',
        address: '123 Test Street',
        legal_person: '张三',
        cert_no: '310000198001010011',
        cert_type: '00',
        mobile: '13800000000',
        email: 'test@example.com',
        app_id: 'app_test_001'
      }
    end

    before do
      allow(Adapay).to receive(:send_request).and_return(
        '{"result_code":"200", "biz_result_code":"S", "biz_msg":"success", "data": {"member_id":"member_test_001"}}'
      )
    end

    context 'parameter validation' do
      it 'should require mandatory parameters' do
        expect { Adapay.create_corp_member({}) }.to raise_error(ArgumentError, /missing required parameters/)

        # Test with missing critical parameters
        incomplete_params = required_params.dup
        incomplete_params.delete(:member_id)
        expect { Adapay.create_corp_member(incomplete_params) }.to raise_error(ArgumentError, /member_id is required/)

        incomplete_params = required_params.dup
        incomplete_params.delete(:order_no)
        expect { Adapay.create_corp_member(incomplete_params) }.to raise_error(ArgumentError, /order_no is required/)

        incomplete_params = required_params.dup
        incomplete_params.delete(:name)
        expect { Adapay.create_corp_member(incomplete_params) }.to raise_error(ArgumentError, /name is required/)
      end
    end

    context 'successful creation' do
      it 'should successfully create a corporate member' do
        response = Adapay.create_corp_member(required_params)
        expect(response).to include('"result_code":"200"')
        expect(response).to include('"biz_result_code":"S"')
        expect(response).to include('"member_id":"member_test_001"')
      end
    end

    context 'error handling' do
      it 'should handle API errors correctly' do
        error_response = '{"result_code":"400", "biz_result_code":"E", "biz_msg":"error message", "error_data": {}}'
        allow(Adapay).to receive(:send_request).and_return(error_response)

        response = Adapay.create_corp_member(required_params)
        expect(response).to include('"result_code":"400"')
        expect(response).to include('"biz_result_code":"E"')
      end
    end

    context 'corp member query' do
      it 'should query corporate member details' do
        allow(Adapay).to receive(:send_request).and_return(
          '{"result_code":"200", "biz_result_code":"S", "biz_msg":"success", "data": {"member_id":"member_test_001", "status":"Normal"}}'
        )

        response = Adapay.query_corp_member(member_id: 'member_test_001')
        expect(response).to include('"result_code":"200"')
        expect(response).to include('"status":"Normal"')
      end
    end
  end
end
