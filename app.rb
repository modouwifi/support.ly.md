require "sinatra"
require "erb"
require "postmark"

configure :production do
  require "newrelic_rpm"
end

get '/' do
  template = File.read(File.expand_path("../template.html.erb", __FILE__))
  renderer = ERB.new(template)
  renderer.result
end

post '/support' do
  p params

  api_key = ENV["POSTMARK_API_KEY"]
  client = Postmark::ApiClient.new(api_key)
  client.deliver(from: 'cs@mochui.net',
                 to: 'afu@forresty.com',
                 subject: "support request from #{params['name']}",
                 text_body: params.inspect)

  'thanks'
end
