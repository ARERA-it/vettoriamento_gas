require 'nokogiri'

xsd = Nokogiri::XML::Schema(File.read('../FlussoFattureGas.xsd'))
doc = Nokogiri::XML(File.read('../empty_schema.xml'))

xsd.validate(doc).each do |error|
   puts error.message
end
