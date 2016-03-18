require 'sinatra'
require 'httparty'
require 'json'

post '/gateway' do
  message = params[:text].gsub(params[:trigger_word], '').strip
  args = message.split(' ')

  s = ''

  station = ''
  day = ''

  m = message.downcase 
  if m.include? 'soup'
    station = :soup
    s += "Mmmmmm.... soup.\n\n"
  elsif m.include? 'global'
    station = :global
    s += "Oui capitan.\n\n"
  elsif m.include? 'grill'
    station = :grill
    s += "Get ready for naptime:\n\n"
  end

  if m.include? 'monday'
    day = :monday
  elsif m.include? 'tuesday'
    day = :tuesday
  elsif m.include? 'wednesday'
    day = :wednesday
  elsif m.include? 'thursday'
    day = :thursday
  elsif m.include? 'friday'
    day = :friday
  else 
    days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    day = days[Date.today.wday].downcase.to_sym
  end



  s += responseForArguments([station, day])

  respond_message s
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