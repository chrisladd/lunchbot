require 'sinatra'
require 'httparty'
require 'json'

post '/gateway' do
  message = params[:text].gsub(params[:trigger_word], '').strip
  s = responseForString(message)
  respond_message s
end

post '/slash' do
  response = {}
  msg = params[:text].downcase
  attachments = []
  if msg.include? 'everyone'
    response[:response_type] = 'in_channel'
  end

  exists = menuExists?
  if exists
    s = responseForString(params[:text])
    attachments << {
      text: s
    }
    response[:text] = "Here's what I found:"

  else 
    response[:text] = "Just have to fetch the menu—ask me again in a sec."
  end

  if attachments.count > 0
    response[:attachments] = attachments
  end

  send_msg_obj response
  if !exists
    cacheCurrentMenu
  end

end


get '/' do 
  ensureCurrentMenuExists
  "<h1>Yep!</h1>"
end

get '/soup' do
  # matches "GET /hello/foo" and "GET /hello/bar"
  # params['name'] is 'foo' or 'bar'
  # n stores params['name']
  stringForStation('soup', 'monday')
end

def send_msg_obj obj
  content_type :json
  obj.to_json
end

def respond_message message
  
  {
      text: message
   }.to_json
end