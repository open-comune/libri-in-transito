# Uso: ruby csv2geojson.rb dataset.csv geocode_dictionary.json

require "csv"
require "json"

csv_dataset = ARGV[0]
geocode_dictionary = JSON.parse(File.read(ARGV[1]))

features = CSV.foreach(csv_dataset, col_sep: ",", headers: true).map do |row|
  title = "#{row["Nome"]}, #{row["Indirizzo"]} #{row["Città"]} #{row["CAP"]}"
  description = "Note: #{row["note"]}"
  {
    type: "Feature",
    geometry: {
      type: "Point",
      coordinates: [
        row["longitudine"],
        row["latitudine"],
      ]
    },
    properties: {
      title: title,
      description: description,
      "marker-symbol": "library", # https://www.mapbox.com/maki-icons/#editor
      "marker-color": "#8f5d00",
    }
  }
end

document = {
  type: "FeatureCollection",
  features: features
}

dest_filename = "#{File.basename(csv_dataset, ".csv")}.geojson"

File.write(dest_filename, JSON.pretty_generate(document))
