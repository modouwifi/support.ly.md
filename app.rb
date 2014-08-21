require "sinatra"
require "sinatra/param"
require "postmark"

require "rack/attack"

require "active_support"

require_relative 'app/modou/models/ticket'

use Rack::Attack

Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

Rack::Attack.blacklist('block bad guys') do |req|
  # Requests are blocked if the return value is truthy
  require "yaml"

  ips = YAML.load_file(File.expand_path('../data/blacklisted_ips.yml', __FILE__))

  ips.include?(req.ip)
end

### Throttle Spammy Clients ###

# If any single client IP is making tons of requests, then they're
# probably malicious or a poorly-configured scraper. Either way, they
# don't deserve to hog all of the app server's CPU. Cut them off!

# Throttle all requests by IP
#
# Key: "rack::attack:#{Time.now.to_i/:period}:req/ip:#{req.ip}"
Rack::Attack.throttle('req/ip', :limit => 10, :period => 300) do |req|
  req.ip
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

  ticket = Modou::Ticket.create_from_params(params)
  p ticket
  puts ticket.to_human_readable_text

  param :name, String, required: true
  param :phone, String, required: true
  param :email, String, format: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/
  param :order_number, String
  param :comment, String, required: true

  valid_reasons = %w{ refund-not-received refund-received replace repair other }.freeze
  param "reason", String, in: valid_reasons, required: true, blank: false

  api_key = ENV["POSTMARK_API_KEY"]

  if api_key
    client = Postmark::ApiClient.new(api_key)

    client.deliver(from:        "cs@mochui.net",
                   to:          "cs@mochui.net",
                   headers:     { 'Name' => ENV['DAIKE_CUSTOM_HEADER'], 'Value' => ticket.user_email },
                   subject:     "support request from #{ticket.user_name}",
                   text_body:   ticket.to_human_readable_text)
  end

  'thanks'
end
