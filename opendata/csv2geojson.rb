# Uso: ruby csv2geojson.rb dataset.csv geocode_dictionary.json

require "csv"
require "json"

csv_dataset = ARGV[0]
geocode_dictionary = JSON.parse(File.read(ARGV[1]))

def is_blank?(value)
  value == nil || value == ""
end

features = CSV.foreach(csv_dataset, col_sep: ",", headers: true).map do |row|
  address_key = [
    row["Indirizzo"],
    row["Città"],
    row["CAP"],
  ].map(&:downcase).map(&:strip).reject do |value|
    is_blank?(value)
  end.join(", ")
  if geocode_dictionary.has_key?(address_key)
    formatted_address = geocode_dictionary[address_key]["formatted_address"]
    title = "#{row["Nome"]}, #{formatted_address}"
    coordinates = geocode_dictionary[address_key]["location"]
    description = [
      {label: "Note", content: row["Note"]}
    ].select do |component|
      !is_blank?(component[:content])
    end.map do |component|
      "#{component[:label]}: #{component[:content]}"
    end.join("<br />")
    {
      type: "Feature",
      geometry: {
        type: "Point",
        coordinates: [
          coordinates["lng"],
          coordinates["lat"],
        ]
      },
      properties: {
        title: title,
        description: description,
        "marker-symbol": "library", # https://www.mapbox.com/maki-icons/#editor
        "marker-color": "#8f5d00",
      }
    }
  else
    next
  end
end

document = {
  type: "FeatureCollection",
  features: features
}

dest_filename = "#{File.basename(csv_dataset, ".csv")}.geojson"

File.write(dest_filename, JSON.pretty_generate(document))
