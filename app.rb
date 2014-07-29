require "sinatra"
require "sinatra/param"
require "postmark"

configure :production do
  require "newrelic_rpm"
end

configure :development do
  set :show_exceptions, false
  set :raise_errors, true
end

helpers Sinatra::Param

helpers do
  def default_params
    {
      :name => nil,
      :phone => nil,
      :email => nil,
      :sn => nil,
      "order_number".to_sym => nil,
      "support_type".to_sym => nil,
      "additional_info".to_sym => nil,
      :error => nil
    }
  end
end

set :raise_sinatra_param_exceptions, true

error Sinatra::Param::InvalidParameterError do
  p params.merge({ error: env['sinatra.error'].param })

  erb :template, locals: params.merge({ error: env['sinatra.error'].param })
end

get '/' do
  erb :template, locals: default_params.merge(params)
end

post '/support' do
  p params

  param :name, String, required: true
  param :phone, String, required: true
  param :email, String, format: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/
  param :order_number, String
  param :additional_info, String, required: true

  param "support_type", String, in: %w{refund-not-received refund-received replace repair other}, required: true, blank: false

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
