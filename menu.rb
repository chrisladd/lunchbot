#!/usr/bin/env ruby

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

def headingsFromPage(page, idx)
  headings = {}
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

  headings
end

def elementsByCombiningAdjacentElements els
  combinedElements = []
  prevElement = nil
  prevY = -1000
  threshold = 13
  els.each do |e|
    elementIsValid = true

    if prevElement && prevElement[:y] - e[:y] < threshold
      t = prevElement[:text].gsub("\n", " ").strip + " " + e[:text].gsub("\n", " ").strip
      prevElement[:text] = t
      elementIsValid = false
    end

    if elementIsValid
      prevElement = e
      combinedElements << e
    end

    prevY = e[:y]
  end

  combinedElements
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

  firstPage = @pageData[0]
  days = [:monday, :tuesday, :wednesday, :thursday, :friday]

  elementsByDay = {}

  # build up an array of headings
  headings = {}

  @pageData.each_with_index do |page, idx|
    headings.merge! headingsFromPage(page, idx)
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

      # combine and adjacent ones
      currentPageDayElements = elementsByCombiningAdjacentElements(currentPageDayElements)

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
