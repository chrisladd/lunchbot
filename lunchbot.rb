#!/usr/bin/env ruby

require 'pdf-reader'
require_relative 'fetchMenu'
require_relative 'renderer'
require 'json'

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

      addElementsToCategoriesIfNecessary(dayElements, categories)
    end

    dayElements.sort! do |a, b|
      b[:y] <=> a[:y]
    end

    elementsByDay[day] = dayElements

  end

  return {
    stations: categories,
    days: elementsByDay
  }
end

def daySymbolForDate(date)

end

def stringForStationForDay(menu, stationId, day)
  station = menu[:stations][stationId]
  elements = station[:elements][day]
  return stringForElements(elements)
end

def stringForElements(elements)
  s = ""
  elements.each do |e|
    s += e[:text]
	s += "\n"
  end

  return s
end

def stringForAllMenuItemsForDay(menu, day)
	s = ''
	elements = menu[:days][day]
	return stringForElements(elements)
end

if !ARGV.empty?
  menu = currentMenu
  station = :soup

  if ARGV.count > 0
  	station = ARGV[0].to_sym	
  end

  if ARGV.count > 1
  	day = ARGV[1].to_sym
  else 
  	day = Date.today.dayname.downcase.to_sym
  end

  s = stringForStationForDay(menu, station, day)
  puts s
	
  puts "\n\nIt has been my pleasure to serve you."
end
