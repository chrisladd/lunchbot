#!/usr/bin/env ruby

require 'httparty'
require 'nokogiri'
require 'date'

@menuLinks = {}

def linksFromURL(url)
	html = HTTParty.get(url).body
	doc = Nokogiri::HTML(html)

	links = doc.css('a')
	hrefs = links.map {|link| link.attribute('href').to_s}.uniq.sort.delete_if {|href| href.empty?}
	return hrefs
end

def currentPDFLink
    host = 'http://radining.compass-usa.com'
    url = host + '/nytimes/Pages/Menu.aspx?Type=Menu'
    
    # get the nytimes page
    links = linksFromURL(url)
    pdfLinks = links.select { |url| url.include? '.pdf' }

    # if there are multiple pdfs, look for the one with the word "Menu" in the last path component
	menus = pdfLinks.select{ |url| url.include? 'Cafe%20Menu' }

	return host + menus[0]
end

def currentMenuFileName
	return "menu-#{Date.today.yday().to_s}.pdf"
end

def cacheCurrentMenu
	menuLink = currentPDFLink
	pdf = HTTParty.get(menuLink).body
	filename = currentMenuFileName
	@menuLinks[filename] = menuLink

	File.open(filename, 'w') { |f| f.write(pdf) }
end

def menuExists?
	filename = currentMenuFileName
	return File.exist? filename
end

def currentMenuLink
	filename = currentMenuFileName
	link = @menuLinks[filename]
	return link
end

def ensureCurrentMenuExists
	if !menuExists?
		cacheCurrentMenu
	end
end
