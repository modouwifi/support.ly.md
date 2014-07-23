require "sinatra"
require "erb"

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
  'thanks'
end
