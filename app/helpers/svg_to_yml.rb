# frozen_string_literal: true

# Helper file to

svg_files = Dir.entries('app/assets/processing/core')

remove_elements = [
  '.DS_Store',
  '.',
  '..'
]
remove_elements.each do |e|
  svg_files.delete(e)
end

filename = 'faces'
yml_file = "app/models/twemoji/13.1.0/#{filename}.yml"

File.open(yml_file, 'w') do |f|
  svg_files.sort.each do |i|
    i.slice!('.svg')
    f.write "'#{i}':\n"
    f.write "  head:\n"
    f.write "  headwear:\n"
    f.write "  cheeks:\n"
    f.write "  mouth:\n"
    f.write "  nose:\n"
    f.write "  eyes:\n"
    f.write "  eyewear:\n"
    f.write "  other:\n"
  end
end

puts
puts 'Success'
puts
