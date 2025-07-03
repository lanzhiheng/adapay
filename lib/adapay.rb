# frozen_string_literal: true

require 'adapay/version'
require 'rest-client'
require 'json'

# 汇付最新文档： https://doc.adapay.tech/document/api/#/member?id=%e5%88%9b%e5%bb%ba%e4%bc%81%e4%b8%9a%e7%94%a8%e6%88%b7%e5%af%b9%e8%b1%a1

module Adapay
  class << self
    attr_accessor :app_id, :app_key, :backup_app_id, :backup_app_key
    attr_reader :merchant_private_key, :platform_public_key

    def extra_data_from_response(response)
      extra_data_from_body(response.body)
    end

    def extra_data_from_body(body)
      data = JSON.parse(body)['data']
      JSON.parse(data)
    end

    def valid_channels
      # https://docs.adapay.tech/api/appendix.html#id2
      %i[
        alipay
        alipay_qr
        alipay_wap
        alipay_lite
        alipay_pub
        alipay_scan
        wx_pub
        wx_lite
        wx_scan
        union
        union_qr
        union_wap
        union_scan
        union_online
        fast_pay
        b2c
        b2b
      ]
    end

    def sdk_version
      "ruby_#{VERSION}"
    end

    def endpoint
      'https://api.adapay.tech'
    end

    def page_endpoint
      'https://page.adapay.tech'
    end

    def merchant_public_key
      merchant_private_key.public_key
    end

    def merchant_private_key=(key)
      @merchant_private_key = OpenSSL::PKey::RSA.new(key)
    end

    def platform_public_key=(key)
      @platform_public_key = OpenSSL::PKey::RSA.new(key)
    end

    def sign(content)
      Base64.strict_encode64(merchant_private_key.sign('SHA1', content))
    end

    def verify(sign, content)
      sign_string = Base64.strict_decode64(sign)
      platform_public_key.public_key.verify('SHA1', sign_string, content)
    end

    def merchant_verify(sign, content)
      sign_string = Base64.strict_decode64(sign)
      merchant_public_key.public_key.verify('SHA1', sign_string, content)
    end

    def id_key_map
      {
        app_id => app_key,
        backup_app_id => backup_app_key
      }
    end

    def build_request_info(method, url, params)
      headers = build_common_headers(params[:app_id])

      if method.to_s.downcase == 'post'
        plain_text = url + params.to_json
        signature = sign(plain_text)

        headers.merge({
                        'Content-type' => 'application/json',
                        signature: signature
                      })
      else
        plain_text = url + get_original_str(params)
        signature = sign(plain_text)

        headers.merge({
                        signature: signature
                      })
      end
    end

    def create_refund(params)
      payment_id = params.delete(:payment_id)
      path = "/v1/payments/#{payment_id}/refunds"

      send_request(:post, path, params)
    end

    # https://docs.adapay.tech/api/trade.html#query-refund
    def query_refund(params)
      path = '/v1/payments/refunds'

      params = { app_id: app_id }.merge(params)

      send_request(:get, path, params)
    end

    def create_payment(params)
      path = '/v1/payments'

      params = { app_id: app_id }.merge(params)

      send_request(:post, path, params)
    end

    # 支付宝小程序跳转支付
    def create_pre_pay_pre_order_payment(params)
      path = '/v1/prePay/preOrder'

      params = { app_id: app_id, adapay_func_code: 'prePay.preOrder' }.merge(params)

      send_page_request(:post, path, params)
    end

    def close_payment(params)
      payment_id = params.delete(:payment_id)
      path = "/v1/payments/#{payment_id}/close"

      send_request(:post, path, params)
    end

    def query_payment_list
      path = '/v1/payments/list'

      params = { app_id: app_id }

      send_request(:get, path, params)
    end

    def query_payment(params)
      payment_id = params.delete(:payment_id)
      path = "/v1/payments/#{payment_id}"

      send_request(:get, path, params)
    end

    ## ---

    # https://docs.adapay.tech/api/trade.html#member-create
    def create_member(params)
      path = '/v1/members'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:post, path, params)
    end

    # 必填：tel_no 用户手机号 user_name 用户姓名 cert_type 00-身份证 cert_id 证件号
    def create_realname_member(params)
      path = '/v1/members/realname'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:post, path, params)
    end

    # https://docs.adapay.tech/api/trade.html#id39
    def query_member(params)
      member_id = params.delete(:member_id)

      params = {
        app_id: app_id
      }.merge(params)

      path = "/v1/members/#{member_id}"

      send_request(:get, path, params)
    end

    # https://docs.adapay.tech/api/trade.html#id40
    def update_member(params)
      path = '/v1/members/update'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:post, path, params)
    end

    # https://docs.adapay.tech/api/trade.html#id42
    def query_member_list(**params)
      path = '/v1/members/list'

      params = { app_id: app_id }.merge(params)

      send_request(:get, path, params)
    end

    def create_settle_account(params)
      path = '/v1/settle_accounts'

      params = {
        app_id: app_id,
        channel: 'bank_account'
      }.merge(params)
      send_request(:post, path, params)
    end

    def query_settle_account(params)
      settle_account_id = params.delete(:settle_account_id)

      path = "/v1/settle_accounts/#{settle_account_id}"

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:get, path, params)
    end

    # https://docs.adapay.tech/api/trade.html#id50
    def delete_settle_account(params)
      path = '/v1/settle_accounts/delete'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:post, path, params)
    end

    # https://docs.adapay.tech/api/trade.html#settle-account-modify
    def update_settle_account(params)
      path = '/v1/settle_accounts/modify'

      params = {
        app_id: app_id
      }.merge(params)
      send_request(:post, path, params)
    end

    def query_settle_account_detail(params)
      path = '/v1/settle_accounts/settle_details'
      params = {
        app_id: app_id
      }.merge(params)

      send_request(:get, path, params)
    end

    def query_settle_account_balance(params)
      path = '/v1/settle_accounts/balance'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:get, path, params)
    end

    # -- 余额支付

    def balance_pay(params)
      path = '/v1/settle_accounts/balancePay'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:post, path, params)
    end

    def balance_refund(params)
      path = '/v1/settle_accounts/balanceRefund'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:post, path, params)
    end

    # Adapay.balance_pay_list({ created_gte: (Date.yesterday.beginning_of_day.to_f * 1000).to_i,
    #                           created_lte: (Date.yesterday.end_of_day.to_f * 1000).to_i })
    def balance_pay_list(params)
      path = '/v1/settle_accounts/balancePayList'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:get, path, params)
    end

    # -- 钱包

    def cash(params)
      path = '/v1/cashs'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:post, path, params)
    end

    def query_cash(params)
      path = '/v1/cashs/stat'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:get, path, params)
    end

    # -- 撤销支付

    # https://docs.adapay.tech/api/trade.html#payment-reverse-create
    def create_payment_reverse(params)
      path = '/v1/payments/reverse'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:post, path, params)
    end

    def query_payment_reverse(params)
      reverse_id = params.delete(:reverse_id)

      path = "/v1/payments/reverse/#{reverse_id}"
      send_request(:get, path, params)
    end

    def query_payment_reverse_list(params)
      params = {
        app_id: app_id
      }.merge(params)

      path = '/v1/payments/reverse/list'
      send_request(:get, path, params)
    end

    # -- 确认支付
    # https://docs.adapay.tech/api/trade.html#payment-confirm-create
    def create_payment_confirm(params)
      params = {
        app_id: app_id
      }.merge(params)

      path = '/v1/payments/confirm'
      send_request(:post, path, params)
    end

    def payment_confirm_reverse(params)
      params = {
        app_id: app_id
      }.merge(params)

      path = '/v1/payments/confirm/reverse'
      send_request(:post, path, params)
    end

    def query_payment_confirm_reverse_detail(params)
      params = {
        app_id: app_id
      }.merge(params)

      path = '/v1/payments/confirm/reverse/details'
      send_request(:get, path, params)
    end

    # https://docs.adapay.tech/api/trade.html#id59
    def query_payment_confirm(params)
      payment_confirm_id = params.delete(:payment_confirm_id)

      path = "/v1/payments/confirm/#{payment_confirm_id}"

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:get, path, params)
    end

    def query_payment_confirm_list(params)
      path = '/v1/payments/confirm/list'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:get, path, params)
    end

    def corp_picture_upload(params, attach_file)
      required_fields = [:file_type]

      raise ArgumentError, 'missing required parameters' if params.empty?

      required_fields.each do |field|
        raise ArgumentError, "#{field} is required" unless params.key?(field)
      end

      path = '/v1/corp/pictureUpload'

      params = {
        app_id: app_id
      }.merge(params)

      # 带文件上传的接口会比较特殊：https://docs.adapay.tech/help/console.html#generatecert
      url = endpoint + path
      headers = build_request_info(:get, url, params)
      url += "?#{get_original_str(params)}"

      payload = { attach_file: File.new(attach_file, 'rb') }
      RestClient::Request.execute(method: :post, url: url, headers: headers, payload: payload)
    end

    # -- 企业用户

    # https://docs.adapay.tech/api/trade.html#corp-member-create
    def create_corp_member(params)
      # Validate required parameters
      required_fields = %i[member_id order_no name]
      raise ArgumentError, 'missing required parameters' if params.empty?

      required_fields.each do |field|
        raise ArgumentError, "#{field} is required" unless params.key?(field)
      end

      path = '/v1/corp/createMembers'

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:post, path, params)
    end

    # Query an existing corporate member
    def query_corp_member(params)
      path = "/v1/corp_members/#{params[:member_id]}"

      params = {
        app_id: app_id
      }.merge(params)

      send_request(:get, path, params)
    end

    private

    def send_request(method, path, params)
      url = endpoint + path
      headers = build_request_info(method, url, params)
      url += "?#{get_original_str(params)}" if method.downcase.to_s == 'get'

      RestClient::Request.execute(method: method, url: url, headers: headers, payload: params.to_json)
    rescue RestClient::BadRequest, RestClient::Unauthorized, RestClient::PaymentRequired => e
      e.response
    end

    def send_page_request(method, path, params)
      url = page_endpoint + path
      headers = build_request_info(method, url, params)
      url += "?#{get_original_str(params)}" if method.downcase.to_s == 'get'

      RestClient::Request.execute(method: method, url: url, headers: headers, payload: params.to_json)
    rescue RestClient::BadRequest, RestClient::Unauthorized, RestClient::PaymentRequired => e
      e.response
    end

    def get_original_str(params)
      params.to_a.sort.map do |a, b|
        value = b.is_a?(Hash) ? b.to_json : b
        "#{a}=#{value}"
      end.join('&')
    end

    def build_common_headers(real_id)
      key = id_key_map[real_id]

      {
        authorization: key,
        sdk_version: sdk_version
      }
    end
  end
end
