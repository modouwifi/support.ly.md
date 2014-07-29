require "sinatra"
require "sinatra/param"
require "postmark"

configure :production do
  require "newrelic_rpm"
end

helpers Sinatra::Param

get '/' do
  default_params =  {
    :name => nil,
    :phone => nil,
    :email => nil,
    "order_number".to_sym => nil,
    "support_type".to_sym => nil,
    "additional_info".to_sym => nil
  }

  erb :template, locals: default_params.merge(params)
end

post '/support' do
  p params

  param :name, String, required: true
  param :phone, String, required: true
  param :email, String, format: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/
  param "order-number", String

  param "support-type", String, in: %w{refund-not-received refund-received replace repair other}, required: true

  api_key = ENV["POSTMARK_API_KEY"]

  if api_key
    client = Postmark::ApiClient.new(api_key)

    client.deliver(from: 'cs@mochui.net',
                   to: 'afu@forresty.com',
                   subject: "support request from #{params['name']}",
                   text_body: params.inspect)
  end

  'thanks'
end
