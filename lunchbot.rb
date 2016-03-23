#!/usr/bin/env ruby

require 'pdf-reader'
require 'json'

require_relative 'fetchMenu'
require_relative 'menu'
require_relative 'renderer'
require 'date'

def elementPassesFilter(element, dietaryFilter)
  if dietaryFilter.length <= 0
    return true
  end

  if dietaryFilter == 'vegan' and element[:text].end_with? 'VG'
    return true
  end

  # there's prolly a smarter way to get items ending in VG or V with a regex or something but i do not know it
  if dietaryFilter == 'vegetarian' and (element[:text].end_with? 'VG' or element[:text].end_with? 'V')
    return true
  end

  return false
end

def stringForStationForDay(menu, stationId, day, dietaryFilter)
  if stationId && stationId == :all
    return stringForAllMenuItemsForDay(menu, day, dietaryFilter)
  end

  station = menu[:stations][stationId]
  elements = station[:elements][day]

  return stringForElements(elements, dietaryFilter)
end

def stringForElement(element)
  s = element[:text]
  s.gsub!(/V$/, ' (vegetarian)')
  s.gsub!(/VG$/, ' (vegan)')
  s = "     #{s}"
  return s
end

def stringForElements(elements, dietaryFilter)
  s = ""
  elements.each do |e|
    if dietaryFilter.length > 0 && !elementPassesFilter(e, dietaryFilter)
      next
    end

    s += stringForElement(e)
    s += "\n"
  end

  return s
end

def stringForAllMenuItemsForDay(menu, day, dietaryFilter)
  elements = menu[:days][day]
  return stringForElements(elements, dietaryFilter)
end

def stringWithSubstitutedTokens(arg_string)
	s = '' + arg_string
  	arg_string = arg_string.downcase
  	arg_string.gsub!('grilled cheese', 'grilled_cheese')
  	arg_string.gsub!('well soup', 'soup_well')

  	# fake a well request.
  	arg_string.gsub!('soup', 'soup soup_well')
  	arg_string.gsub!('sandwich', 'hero')
  	arg_string.gsub!('healthy soup', 'soup_well')
  	arg_string.strip!

  	arg_string
end

def responseForString(arg_string)


  s = ''
  arg_string = stringWithSubstitutedTokens(arg_string)
  
  if arg_string.include? 'pdf'
    return {
      heading: "OK, no hard feelings. Here's a link to the full menu:",
      body: currentPDFLink
    }  
  end

  menu = currentMenu



  stationIds = []
  if !arg_string.empty?
    menu[:stations].each do |stationId, stationHash|
      if arg_string.include? stationId.to_s
        stationIds << stationId
      end
    end  
  end

  # Kevin adding vegan/vegetarian filters
  dietaryFilter = ''
  if arg_string.include? 'vegan'
    dietaryFilter = 'vegan'
  end

  if arg_string.include? 'vegetarian'
    dietaryFilter = 'vegetarian'
  end

  targetDate = nil
  days = ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
  days.each do |day|
    if arg_string.include? day
      targetDate = day.to_sym
      break
    end
  end

  if !targetDate
    wDay = Date.today.wday
    if arg_string.include? 'tomorrow'
      wDay = (wDay + 1) % 7
    end

    targetDate = days[wDay].to_sym
  end

  stationSpecificText = ''
  if stationIds.count > 0
    stationIds.each do |id|
      begin
        stationSpecificText += "#{menu[:stations][id][:display]}:"
        stationSpecificText += stringForStationForDay(menu, id, targetDate, dietaryFilter)
        stationSpecificText += "\n"
      rescue
      end  
    end
  end

  headingText = ''
  if stationSpecificText.length > 0
    headingText = "I found these on the menu for #{targetDate.to_s.capitalize}:"
    s = stationSpecificText
  else 
    begin
      headingText = "Lots for lunch on #{targetDate.to_s.capitalize}:\n\n"
      menu[:stations].each do |stationId, stationHash|
          s += "#{stationHash[:display]}:\n"
          s += stringForStationForDay(menu, stationId, targetDate, dietaryFilter)
          s += "\n\n"
      end  
    rescue
    end
  end
  
  if s.length == 0
    headingText = "I'm sorry, I didn't quite get that. Maybe you should go eat outside?"
  end

  return {
  	heading: headingText,
  	body: s
  }
end

begin
  obj = responseForString(ARGV.join(' '))
  puts obj[:heading]
  puts obj[:body]
rescue
end
