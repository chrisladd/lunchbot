require 'sinatra'
require 'httparty'
require 'json'

post '/gateway' do
  message = params[:text].gsub(params[:trigger_word], '').strip
  args = message.split(' ')
  respond_message responseForArguments(args)
end

get '/' do 
  "<h1>Yep!</h1>"
end

get '/soup' do
  # matches "GET /hello/foo" and "GET /hello/bar"
  # params['name'] is 'foo' or 'bar'
  # n stores params['name']
  stringForStation('soup', 'monday')
end

def respond_message message
  content_type :json
  {:text => message}.to_json
end