#!/usr/bin/env ruby

require 'json'
require 'yaml'
require 'byebug'

max = 3849
shelfbottom = 1488

annos = {}

files = Dir.glob('../zannotations/*.json')

files.each do |file|
  parts = File.read(file).split("---\n")
  yaml = YAML.load(parts[1])
  annos[yaml['order']] = {
    file: file.split('/').last,
    yaml: yaml,
    json: JSON.parse(parts[2])
  }
end

keys = annos.keys.sort
top = keys.last
prevbox = nil
boundaries = {}

keys.each do |key|
  x,y,w,h = annos[key][:json]['target']['selector']['value'].sub('xywh=', '').split(',')
  left = x.to_f.round
  right = left + w.to_f.round
  top = y.to_f.round
  bottom = shelfbottom
  if prevbox
    left = ((prevbox[:right] + left) / 2).round
  else
    left = 0
  end
  if key == keys.last
    right = max
  end
  prevbox = { left: left, right: right, top: top, bottom: bottom }

  # create new xywh for this anno
  # like xywh=2006.62744140625,420.2785339355469,76.982421875,1052.2295227050781
  
  annos[key][:json]['target']['selector']['value'] = "xywh=#{left},#{top},#{right - left},#{bottom-top}"

  # output
  output = annos[key][:yaml].to_yaml + "---\n" + JSON.pretty_generate(annos[key][:json])

  File.open("../zannotations-new/#{annos[key][:file]}", 'w') { |file|
    file.write(output)
  }
end

byebug

puts 'done'