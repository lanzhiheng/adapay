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

## 1. Create Payment in other application with backup_app_id

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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/adapay. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/adapay/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Adapay project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/adapay/blob/master/CODE_OF_CONDUCT.md).
