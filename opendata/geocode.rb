require "uri"
require "open-uri"
require "pp"
require "json"
require "dotenv"
require "fileutils"

Dotenv.load

def is_blank?(value)
  value == nil || value == ""
end

module Geocoder
  def self.geocode(address:, country: "IT", language: "it", api_key:)
    params = {
      key: api_key,
      address: address,
      language: language,
    }
    components = {
      country: country,
    }
    encoded_components = "components=" + components.map do |key, value|
      "#{key}:#{value}"
    end.join("|")
    encoded_params = (params.map do |key, value|
      "#{key}=#{URI.encode(value)}"
    end + [encoded_components]).join("&")
    format = "json"
    base_address = "https://maps.googleapis.com/maps/api/geocode/#{format}"
    address = "#{base_address}?#{encoded_params}"
    response = open(address).read
    JSON.parse(response)
  end
end

require "csv"

addresses = CSV.foreach("dataset.csv", headers: true).map do |row|
  [
    row["Indirizzo"],
    row["Città"],
    row["CAP"],
  ].map(&:downcase).map(&:strip).reject do |value|
    is_blank?(value)
  end.join(", ")
end.uniq

quotas = {
  daily: {
    usage: 0,
    period: 60 * 60 * 24, # 1 day
    limit: 2_500,
    cooldown: nil, # doesn't wait
  },
  per_second: {
    usage: 0,
    period: 1,
    limit: 50,
    cooldown: 0.5,
  },
}

before = Time.now

def quota_exceeded(before:, quota:, now:)
  quota[:usage] >= quota[:limit] && (now - before) <= quota[:period]
end

geocode_mapping = addresses.map do |address|
  quotas.each do |label, quota|
    if quota_exceeded(before: before, now: Time.now, quota: quota)
      puts ""
      puts "Quota usage exceeded: [#{label}] used = #{quota[:usage]}, limit = #{quota[:limit]}"
      if quota[:cooldown]
        print "Performing cooldowns (#{quota[:cooldown]} secs): "
        begin
          sleep quota[:cooldown]
          print "."
        end while quota_exceeded(before: before, now: Time.now, quota: quota)
        puts ""
        puts "Resetting quota usage [#{label}]"
        quota[:usage] = 0
        before = Time.now
      else
        puts "No cooldown period specified for quota [#{label}], exiting"
      end
    else
      quota[:usage] += 1
    end
  end
  geocode_result = Geocoder.geocode(address: address, country: "IT", language: "it", api_key: ENV["GEOCODER_API_KEY"])
  symbol = if geocode_result["status"] == "OK"
    "+"
  else
    "X"
  end
  print symbol
  result = {
    address: address,
    result: geocode_result,
  }
  result
end

File.write("geocode_mapping.json", JSON.pretty_generate(geocode_mapping))
