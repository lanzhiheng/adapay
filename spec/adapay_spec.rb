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

    context 'file upload' do
      let(:attach_file_path) { './spec/fixtures/test_upload.txt' }
      
      before do
        File.write(attach_file_path, 'Test file content') unless File.exist?(attach_file_path)
        allow(RestClient::Request).to receive(:execute).and_return(
          '{"result_code":"200", "biz_result_code":"S", "biz_msg":"success with file", "data": {"member_id":"member_test_001"}}'
        )
      end
      
      after do
        File.delete(attach_file_path) if File.exist?(attach_file_path)
      end
      
      it 'should handle file upload correctly' do
        response = Adapay.create_corp_member(required_params, attach_file_path)
        expect(response).to include('"result_code":"200"')
        expect(response).to include('"biz_msg":"success with file"')
      end
      
      it 'should handle missing file gracefully' do
        non_existent_file = './spec/fixtures/non_existent_file.txt'
        expect(Adapay).to receive(:send_request).with(:post, '/v1/corp_members', hash_including(required_params))
        Adapay.create_corp_member(required_params, non_existent_file)
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