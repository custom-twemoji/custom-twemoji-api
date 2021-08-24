# frozen_string_literal: true

# Helper file to

svg_files = Dir.entries('assets/processing/core')

remove_elements = [
  '.DS_Store',
  '.',
  '..'
]
remove_elements.each do |e|
  svg_files.delete(e)
end

filename = 'face'
yml_file = "app/models/twemoji/13.1.0/#{filename}.yml"

File.open(yml_file, 'w') do |f|
  svg_files.sort.each do |i|
    i.slice!('.svg')
    f.write "'#{i}':\n"
    f.write "  0: ''\n"
    f.write "  1: ''\n"
    f.write "  2: ''\n"
    f.write "  3: ''\n"
    f.write "  4: ''\n"
    f.write "  5: ''\n"
    # f.write "  eyewear:\n"
    # f.write "  other:\n"
  end
end

puts
puts 'Success'
puts
