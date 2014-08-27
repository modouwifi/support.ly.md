require "sinatra"
require "sinatra/param"
require "postmark"

require "rack/attack"

require "active_support"

require_relative 'app/modou/models/ticket'

class QiniuCDN
  require "nokogiri"

  def initialize(app)
    require "qiniu"
    Qiniu.establish_connection! access_key: ENV['QINIU_ACCESS_KEY'], secret_key: ENV['QINIU_SECRET_KEY']

    @app = app
  end

  def replace_asset!(body_string, asset_path)
    asset_path = asset_path[1..-1] if asset_path[0] == '/'
    cdn_url = "http://#{ENV['QINIU_BUCKET']}.qiniudn.com/#{asset_path}"
    body_string.gsub!(asset_path, Qiniu::Auth.authorize_download_url(cdn_url))
  end

  def call(env)
    status_code, headers, body = @app.call(env)

    headers.delete('Content-Length')

    body_string = body.join

    doc = Nokogiri::HTML(body_string)
    doc.css('link').select { |link| link['href'] =~ /assets/ }.map do |link|
      replace_asset!(body_string, link['href'])
    end
    doc.css('a').select { |a| a['href'] =~ /assets/ }.map do |a|
      replace_asset!(body_string, a['href'])
    end
    doc.css('script').select { |node| node['src'] =~ /assets/ }.map do |node|
      replace_asset!(body_string, node['src'])
    end

    [status_code, headers, [body_string]]
  end
end

use QiniuCDN

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
