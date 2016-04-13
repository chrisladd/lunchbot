#!/usr/bin/env ruby

require 'httparty'
require 'json'
require 'date'

@weatherCache = {}

def keyForCurrentDate(city, state)
	d = DateTime.now
	return "#{city}-#{state}-#{d.year.to_s}-#{d.month.to_s}-#{d.day.to_s}_#{d.hour.to_s}"
end

def clearCache
	@weatherCache.keys.each do |k|
		@weatherCache.delete(k)
	end
end

def getWeather(city, state)
	cacheKey = keyForCurrentDate(city, state)
	weather = @weatherCache[cacheKey]

	if !weather
		city = city.gsub(' ', '%20')
		url = "https://query.yahooapis.com/v1/public/yql?q=select%20*%20from%20weather.forecast%20where%20woeid%20in%20(select%20woeid%20from%20geo.places(1)%20where%20text%3D%22#{city}%2C%20#{state}%22)&format=json&env=store%3A%2F%2Fdatatables.org%2Falltableswithkeys"
		jsonTxt = HTTParty.get(url).body
		if jsonTxt
			weather = JSON.parse(jsonTxt)

			# it wasn't in our cache, so let's save it
			# and, while we're at it, get rid of any previously cached weather
			clearCache()
			@weatherCache[cacheKey] = weather
		end
	end

	return weather
end

def getCurrentWeatherConditions(city, state)
	conditions = {}
	weather = getWeather(city, state)

	if weather
		conditions = weather['query']['results']['channel']['item']['condition']
	end

	return conditions
end
