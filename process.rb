#!/usr/bin/env ruby

require 'json'
require 'marc'
require 'byebug'

shelf = ['Z001039 B000056 C000047 002016', 'Z001041 C000055 002011']

books = []

# reading records from a batch file
reader = MARC::Reader.new('z3950/full.mrc', :external_encoding => "UTF-8")
bookcount = 0

for record in reader
  callnum = "#{record['050']['a']} #{record['050']['b']}"
  parts = callnum.gsub('.', ' ')
            .gsub(/\s+/, ' ')
            .gsub(/(\d)([^\d])/,'\1|\2')
            .gsub(/([^\d])(\d)/,'\1|\2')
            .split('|')
  sortkey = ''
  parts.each do |part|
    if part.match(/\d+/)
      sortkey += part.rjust(6, '0')
    else
      sortkey += part
    end
  end
  
  next unless (sortkey >= shelf[0]) and (sortkey <= shelf[1])

  bookcount += 1
  id = record['001'].value

  authors = []
  record.each_by_tag(['100', '700', '710']) do |author|
    a = author['a'].strip.sub(/(\w\w)[\.\,]$/, '\1').split(',')
    # byebug
    authors << ((a.count == 2) ? "#{a[1]} #{a[0]}".strip : a[0])
  end

  # work through holdings
  locations = []
  holdings = []
  record.each_by_tag('926') do |holding|
    holdings << { location: holding['a'], status: holding['b'], type: holding['d'], copy: holding['f'] }
    locations << holding['a']
  end
  
  year = ''
  record.each_by_tag(['260', '264']) do |pub|
    year = pub['c'].gsub(/[^\d]/, '') if pub['c']
  end
  
  hathi = record['583'] ? record['583']['d'] : nil

  books << {
    id: id,
    authors: authors,
    title: "#{record['245']['a']} #{record['245']['b']}".strip.gsub(' :', ':').sub(/ ?[\.\/]$/, ''),
    year: year,
    callnum: callnum,
    sortkey: sortkey,
    hathi: hathi,
    locations: locations,
    holdings: holdings
  }
  
  File.open("dump/#{id}.txt", 'w') { |file| file.write(record.to_s) }

end

puts "Count: #{bookcount}"

books.sort! { |a,b| a[:sortkey] <=> b[:sortkey] }

books.each do |book|
  puts "#{book[:id]}    #{book[:callnum]}: #{book[:title]}"
end

File.write('data/full.json', JSON.pretty_generate(books))

# fold books into nearest previous shelved book

previousbook = nil
foldedbooks = []

books.each do |book|
  if book[:holdings].select { |h| h[:location] == "UAHSS" && h[:status] == "ON_SHELF" }.count > 0
    # this is a shelved book
    book[:fold] = []
    foldedbooks << previousbook if previousbook
    previousbook = book
  else
    # this is not a shelved book
    previousbook[:fold] << book
  end
end

foldedbooks << previousbook

File.write('data/folded.json', JSON.pretty_generate(foldedbooks))

puts 'done'