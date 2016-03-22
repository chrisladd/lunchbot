#!/usr/bin/env ruby

require 'pdf-reader'
require 'json'

require_relative 'fetchMenu'
require_relative 'renderer'
require 'date'

class Date
  def dayname
    DAYNAMES[self.wday]
  end

  def abbr_dayname
    ABBR_DAYNAMES[self.wday]
  end
end


def pointIsBetweenPoints(p, x1, x2)
  if p >= x1
    if p <= x2
      return true
    end
  end

  return false
end

def elementIntersectsControl(element, dayConfig)
  x1 = dayConfig[:x]
  x2 = x1 + dayConfig[:width]

  eX1 = element[:x]
  eX2 = eX1 + element[:width]

  if pointIsBetweenPoints(eX1, x1, x2) ||
      pointIsBetweenPoints(eX2, x1, x2) ||
      pointIsBetweenPoints(x1, eX1, eX2)
    return true
  end


  return false
end

def addElementsToCategoriesIfNecessary(elements, categories)
  categories.each do |categoryId, category|
    elements.each do |element|
      if element[:page] == category[:page]
        if element[:y] >= category[:min_y] && element[:y] <= category[:max_y]
          a = category[:elements][element[:day]]
          if !a
            a = []
            category[:elements][element[:day]] = a
          end

          a << element
        end
      end
    end
  end

end

def currentMenu
  ensureCurrentMenuExists
  reader = PDF::Reader.new(currentMenuFileName())

  receiver = PDF::Reader::MenuPageTextReceiver.new
  @pageData = []

  reader.pages.each do |page|
    page.walk(receiver)

    @pageData << {
      positions: receiver.positions(),
      keyedPositions: receiver.keyedPositions()
    }
  end

  categories = {
    soup: {
      id: :soup,
      display: "Soup",
      min_y: 800,
      max_y: 930,
      page: 0,
      elements: {}

    },
    global: {
      id: :global,
      display: "Global",
      min_y: 458,
      max_y: 1008,
      page: 1,
      elements: {}

    },
    grill: {
      id: :grill,
      display: "Grill",
      min_y: 440,
      max_y: 688,
      page: 0,
      elements: {}

    }
  }

  firstPage = @pageData[0]
  days = [:monday, :tuesday, :wednesday, :thursday, :friday]

  elementsByDay = {

  }

  # build up an array of headings
  headings = {}

  @pageData.each_with_index do |page, idx|
    prevHeading = nil
    page[:positions].each do |el|
      if el[:x] < 95
        id = el[:text].strip.downcase.gsub(' ', '_').gsub(/\W+/, '')

        if id.include? 'asian'
          id = 'asian'
        end

        isValid = true
        if id =~ /\d/
          isValid = false
        end

        if isValid
          h = {
            id: id.to_sym,
            display: el[:text].strip,
            max_y: el[:y],
            page: idx,
            elements: {}
          }

          headings[h[:id]] = h

          if prevHeading
            prevHeading[:min_y] = el[:y]
          end

          prevHeading = h
        end

      end

      if prevHeading
        prevHeading[:min_y] = 0
      end
    end
  end

  days.each do |day|
    dayElements = []
    dayConfig = firstPage[:keyedPositions][day.to_s]

    @pageData.each_with_index do |page, idx|
      currentPageDayElements = []
      page[:positions].each do |element|

        if element != dayConfig && elementIntersectsControl(element, dayConfig)
          element[:page] = idx
          element[:day] = day

          currentPageDayElements << element
          dayElements << element
        end
      end

      currentPageDayElements.sort! do |a, b|
        b[:y] <=> a[:y]
      end

      addElementsToCategoriesIfNecessary(currentPageDayElements, headings)
    end

    dayElements.sort! do |a, b|
      b[:y] <=> a[:y]
    end

    elementsByDay[day] = dayElements

  end

  return {
    stations: headings,
    days: elementsByDay
  }
end

def daySymbolForDate(date)

end

def elementPassesFilter(element, dietaryFilter)

  if dietaryFilter.length <= 0
    return true
  end

  if dietaryFilter == 'vegan' and element[:text].end_with? 'VG'
    puts element[:text]
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

def stringForElements(elements, dietaryFilter)

  s = ""
  elements.each do |e|
    if dietaryFilter.length > 0 && !elementPassesFilter(e, dietaryFilter)
      next
    end

    s += e[:text]
    s += "\n"
  end

  return s
end

def stringForAllMenuItemsForDay(menu, day, dietaryFilter)
  s = ''
  elements = menu[:days][day]
  return stringForElements(elements, dietaryFilter)
end

def stringForStation(station, day)
  if station
    station = station.to_sym
  end

  if !station
    station = :soup
  end

  if day
    day = day.to_sym
  end

  if !day
    day = :monday
  end

  menu = currentMenu
  s = stringForStationForDay(menu, station, day, dietaryFilter)

  return s
end

def responseForString(arg_string)
  s = ''
  arg_string = arg_string.downcase
  arg_string.gsub!('grilled cheese', 'grilled_cheese')
  arg_string.gsub!('well soup', 'soup_well')

  # fake a well request.
  arg_string.gsub!('soup', 'soup soup_well')
  arg_string.gsub!('sandwich', 'hero')
  arg_string.gsub!('healthy soup', 'soup_well')
  arg_string.strip!

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
        stationSpecificText += "*#{menu[:stations][id][:display]}*:\n"
        stationSpecificText += stringForStationForDay(menu, id, targetDate, dietaryFilter)
        stationSpecificText += "\n"
      rescue
      end  
    end
  end

  if stationSpecificText.length > 0
    s = "I found these on the menu for #{targetDate.to_s.capitalize}:\n\n#{stationSpecificText}"
  else 
    begin
      s += "Lots for lunch on #{targetDate.to_s.capitalize}:\n\n"
      menu[:stations].each do |stationId, stationHash|
          s += "*#{stationHash[:display]}*:\n"
          s += stringForStationForDay(menu, stationId, targetDate, dietaryFilter)
          s += "\n\n"
      end  
    rescue
    end
  end
  
  if s.length == 0
    s += "I'm sorry, I didn't quite get that. Maybe you should go eat outside?"
  end

  return s
end

begin
  s = responseForString(ARGV.join(' '))
  puts s
rescue
end
