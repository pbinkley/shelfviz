#!/usr/bin/env ruby

require 'json'
require 'yaml'
require 'byebug'

data = JSON.parse(File.read('data/full.json'))

uahss = []

items = data.select { |item| item['locations'].include? 'UAHSS' }

items.each do |item|
  item['holdings'].each do |holding|
    next unless holding['location'] == 'UAHSS'
    next if holding['status'] == 'CURRICULUM'

    uahss << {
      'id' => item['id'],
      'callnum' => "#{item['callnum']} c.#{holding['copy']}",
      'title' => item['title'],
      'year' => item['year'],
      'status' => holding['status']
    }
  end
end

File.open("data/uahss.yml", "w") { |file| file.write(uahss.to_yaml) }

puts 'done'
