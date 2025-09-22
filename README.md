# Adapay

Welcome to Adapay! This is a simple gem for Adapay. What is Adapay? It's an pay platform which integrating multi pay channel. So you can use Alipay, Wechat, Union, etc.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'adapay'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install adapay

## Usage

### Configuration

Create `Create config/initializer/adapay.rb` and put following configurations into it

```
Adapay.app_id = 'Your Adapay App Id
Adapay.app_key = 'Your Adapay App Key'
Adapay.backup_app_id = 'Your Backup Adapay App Id'
Adapay.backup_app_key = 'Your Backup Adapay App Key'
# Private key which generate by your platform
Adapay.merchant_private_key = File.read('merchant_private_key')
# Public Key From Adapay Platform
Adapay.platform_public_key = File.read('adapay_platform_public_key')
```

### backup_app_id

What is `backup_app_id`? Imagine, if you have more than one applications in Adapay, most of api you want to issue in application with `app_id` and others on `backup_app_id`. How to do that? You Just can call the method with params `app_id=xxxx`.

### 1. Create Payment in default application

``` ruby
params = {
  order_no: 'number',
  pay_channel: 'alipay',
  pay_amt: format('%.2f', 100),
  expend: {
    open_id: ''
  },
  pay_mode: 'delay',
  goods_title: 'payment',
  goods_desc: 'payment',
  device_info: {
    device_ip: '127.0.0.1'
  },
  notify_url: notification_url
}

res = Adapay.create_refund(params)
```

## 2. Create Payment in other application with backup_app_id

``` ruby
params = {
  order_no: 'number',
  pay_channel: 'alipay',
  pay_amt: format('%.2f', 100),
  expend: {
    open_id: ''
  },
  pay_mode: 'delay',
  goods_title: 'payment',
  goods_desc: 'payment',
  device_info: {
    device_ip: '127.0.0.1'
  },
  notify_url: notification_url
}

res = Adapay.create_refund(params.merge(app_id: Adapay.backup_app_id))
```

This Gem can auto search the `backup_app_key` from `Adapay.id_key_map`. You can check the source code from [here](https://github.com/lanzhiheng/adapay/blob/master/lib/adapay.rb#L80).

### 3. Create Corporate Member

To create a corporate member account, you need to provide required corporate information:

``` ruby
params = {
  member_id: 'corp_member_001',    # Unique merchant member ID
  order_no: 'order_no_001',        # Unique order number
  name: 'Test Company Ltd.',       # Corporate name
  prov_code: '310000',             # Province code
  city_code: '310100',             # City code
  district_code: '310101',         # District code
  address: '123 Business Road',    # Business address
  legal_person: '张三',            # Legal representative name
  cert_no: '310000198001010011',   # ID card number
  cert_type: '00',                 # ID card type
  mobile: '13800000000',           # Contact mobile
  email: 'test@example.com'        # Contact email
}

# Create corporate member without file attachment
response = Adapay.create_corp_member(params)
```

#### Required Parameters

| Parameter     | Description                              | Required |
|---------------|------------------------------------------|----------|
| member_id     | Merchant's unique identifier             | Yes      |
| order_no      | Unique order number                      | Yes      |
| name          | Corporate name                           | Yes      |
| prov_code     | Province code                            | Yes      |
| city_code     | City code                                | Yes      |
| district_code | District code                            | Yes      |
| address       | Business address                         | Yes      |
| legal_person  | Legal representative name                | Yes      |
| cert_no       | ID card number of legal representative   | Yes      |
| cert_type     | ID card type                             | Yes      |
| mobile        | Contact mobile phone                     | Yes      |
| email         | Contact email                            | Yes      |

#### File Upload

You can attach corporate documentation files (business license, etc.) when creating a member:

``` ruby
# Path to attachment file
attach_file_path = '/path/to/business_license.jpg'

# Create corporate member with file attachment
response = Adapay.create_corp_member(params, attach_file_path)
```

The file will be uploaded using multipart/form-data format. The system supports common image formats such as PNG, JPG, JPEG, etc.

#### Response Handling

``` ruby
# Parse the JSON response
result = JSON.parse(response)

if result['result_code'] == '200' && result['biz_result_code'] == 'S'
  # Success case
  member_id = result['data']['member_id']
  puts "Corporate member created successfully: #{member_id}"
else
  # Error handling
  error_code = result['biz_result_code']
  error_msg = result['biz_msg']
  puts "Failed to create corporate member: #{error_msg} (#{error_code})"
end
```

#### Query Corporate Member

You can query a corporate member's information using its member_id:

``` ruby
# Query corporate member details
response = Adapay.query_corp_member(member_id: 'corp_member_001')
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/adapay. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/adapay/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Adapay project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/adapay/blob/master/CODE_OF_CONDUCT.md).