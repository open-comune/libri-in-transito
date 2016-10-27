require "json"

dictionary_filename = "geocode_dictionary.json"
geocode_dictionary = if File.exist?(dictionary_filename)
  JSON.parse(File.read(dictionary_filename))
else
  {}
end

geocode_mapping = JSON.parse(File.read("geocode_mapping.json"))

geocode_mapping.each do |record|
  data = record["result"]["results"][0]
  address = record["address"].downcase
  geocode_dictionary[address] = {
    formatted_address: data["formatted_address"],
    location: data["geometry"]["location"],
    place_id: data["place_id"],
  }
end

File.write(dictionary_filename, JSON.pretty_generate(geocode_dictionary))
