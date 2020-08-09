#!/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'json'
require 'pry'
require 'scraped'
require 'wikidata_ids_decorator'

require_relative 'lib/remove_notes'
require_relative 'lib/unspan_all_tables'

# The Wikipedia page with a list of Mars Missions
class MissionsPage < Scraped::HTML
  decorator RemoveNotes
  decorator WikidataIdsDecorator::Links

  field :missions do
    list_table.xpath('.//tr[td]').map { |td| fragment(td => Mission) }.map(&:to_h)
  end

  private

  def list_table
    noko.xpath('.//table[.//th[contains(., "Spacecraft")]]').first
  end
end

# Each mission row in the table
class Mission < Scraped::HTML
  field :spacecraft do
    tds[0].css('a').text.tidy
  end

  field :spacecraft_id do
    tds[0].css('a/@wikidata').text
  end

  field :launch_date do
    Date.parse(tds[1].text)
  end

  field :operator do
    tds[2].css('a').map(&:text).map(&:tidy).first
  end

  field :mission do
    tds[3].text.tidy
  end

  field :outcome do
    tds[4].text.tidy
  end

  field :remarks do
    tds[5].text.tidy
  end

  field :carrier do
    tds[6].text.tidy
  end

  field :carrier_id do
    tds[6].css('a/@wikidata').first.text
  end

  private

  def tds
    noko.css('td')
  end
end

url = 'https://en.wikipedia.org/wiki/List_of_missions_to_Mars'
page = MissionsPage.new(response: Scraped::Request.new(url: url).response)
puts JSON.pretty_generate page.missions
