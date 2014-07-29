require "sinatra"
require "sinatra/param"
require "postmark"

configure :production do
  require "newrelic_rpm"
end

helpers Sinatra::Param

get '/' do
  erb :template
end

post '/support' do
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
