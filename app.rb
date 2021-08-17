require 'nokogiri'
require 'sinatra'

# Bottom to top layer
DEFAULT_PARTS_ORDER = [
  :head,
  :cheeks,
  :mouth,
  :nose,
  :eyes,
  :eyewear,
  :other
]

get '/' do
  params = validate_and_symbolize

  def get_file(id)
    File.open("assets/#{id}.svg") { |f| Nokogiri::XML(f) }
  end

  def get_part_from_file(part, file_name)
    file = get_file(file_name)
    file.at_css("[id='#{part}']")
  end

  def write_output(file)
    xml = file.to_xml

    File.open("tmp/out.svg", "w") do |f|
      f.write(xml)
    end

    xml
  end

  base_file = get_file('base').at(:svg)

  if params[:order] == 'manual'
    params.each do |key, value|
      next if key == :order
      base_file.add_child(get_part_from_file(key, value).to_s) unless value.nil?
    end
  else
    DEFAULT_PARTS_ORDER.each do |key|
      value = params[key]
      base_file.add_child(get_part_from_file(key, value).to_s) unless value.nil?
    end
  end

  write_output(base_file)
end

private

def validate_and_symbolize
  valid_params = [DEFAULT_PARTS_ORDER, :order].flatten
  Hash[
    params.map do |(k,v)|
      [k.to_sym,v]
    end
  ].select { |key, value| valid_params.include?(key) }
end
