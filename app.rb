require "sinatra"
require "sinatra/param"
require "postmark"

require "rack/attack"

use Rack::Attack

Rack::Attack.blacklist('block bad guys') do |req|
  # Requests are blocked if the return value is truthy
  require "yaml"

  ips = YAML.load_file(File.expand_path('../data/blacklisted_ips.yml', __FILE__))

  ips.include?(req.ip)
end

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
      :order_number => nil,
      :reason => nil,
      :comment => nil,
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
  param :comment, String, required: true

  param "reason", String, in: %w{refund-not-received refund-received replace repair other}, required: true, blank: false

  api_key = ENV["POSTMARK_API_KEY"]

  if api_key
    client = Postmark::ApiClient.new(api_key)

    require "yaml"

    # client.deliver(from:        "cs@mochui.net",
    #                to:          "cs@mochui.net",
    #                subject:     "support request from #{params['name']}",
    #                text_body:   params.inspect)
  end

  'thanks'
end
