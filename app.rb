require 'sinatra'
require 'httparty'
require 'json'

post '/gateway' do
  message = params[:text].gsub(params[:trigger_word], '').strip
  r = responseForString(message)
  respond_message r[:body]
end

post '/slash' do
  response = {}
  msg = nil

  if params[:text]
    msg = params[:text].downcase.strip
  end

  if !msg || msg.length == 0
    msg = 'all'
  end
  
  attachments = []
  if msg.include? 'everyone'
    response[:response_type] = 'in_channel'
  end

  begin
    b = responseForString(msg)
  
    if b[:body]
      attachments << {
        text: b[:body]
      }  
    end
  
    if b[:heading]
      response[:text] = b[:heading]  
    end
  
    if attachments.count > 0
      response[:attachments] = attachments
    end

  rescue
    response = {
      text: "Sorry, Lunchbot is currently encountering a food coma. Try again soon."
    }
  end

  
  send_msg_obj response
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
    text: message.force_encoding("utf-8")
  }.to_json
end
