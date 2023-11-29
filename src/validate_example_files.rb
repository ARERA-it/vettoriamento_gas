require 'nokogiri'

xsd = Nokogiri::XML::Schema(File.read('../FlussoFattureGas.xsd'))

files = Dir["../esempi/*.xml"] # ["../esempi/example_01.xml"]

files.each do |file|
  doc = Nokogiri::XML(File.read(file))
  puts "Validating #{file}"
  xsd.validate(doc).each do |error|
     puts error.message
  end
end
