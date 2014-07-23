require "sinatra"

configure :production do
  require "newrelic_rpm"
end

get '/' do
  "hello world"
end
