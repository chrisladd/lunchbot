#!/usr/bin/env ruby

require 'httparty'
require 'json'

def getWeather(city, state)
	weather = nil
	city = city.gsub(' ', '%20')
	url = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22#{city}%2C%20#{state}%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
	jsonTxt = HTTParty.get(url).body
	if jsonTxt
		weather = JSON.parse(jsonTxt)
	end

	return weather
end
