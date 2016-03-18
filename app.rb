require 'sinatra'
require 'httparty'
require 'json'

post '/gateway' do
  respond_message 'What\'s for lunch!'
  # message = params[:text].gsub(params[:trigger_word], '').strip

  # action, repo = message.split('_').map {|c| c.strip.downcase }
  # repo_url = "https://api.github.com/repos/#{repo}"

  # case action
  #   when 'issues'
  #     resp = HTTParty.get(repo_url)
  #     resp = JSON.parse resp.body
  #     respond_message "There are #{resp['open_issues_count']} open issues on #{repo}"
  # end
end

get '/' do 
  "<h1>Yep!</h1>"
end

get '/stations/:stationId/:day' do |n|
  # matches "GET /hello/foo" and "GET /hello/bar"
  # params['name'] is 'foo' or 'bar'
  # n stores params['name']
  "Hello #{stationId} - #{day}!"
end

def respond_message message
  content_type :json
  {:text => message}.to_json
end