#!/usr/bin/env ruby
require 'csv'
require 'chronic'

# integers, currency, percents (truncate)
FLOAT_REGEX = /^(?<neg>[\(-]?)\$?(?<val>\d[\d,\.]*)(?<perc>%?)\)?\s*$/

file_path = ARGV[0]
raise 'you need to pass a csv to import' unless file_path

number_converter =
  proc do |field|
    match = FLOAT_REGEX.match(field)
    if match
      field = match[:val] && match[:val].to_f || match
      field *= -1 if !match[:neg].empty?
      field /= 100 if !match[:perc].empty?
    end
    field
  end

time_converter =
  proc do |field|
    Chronic.parse(field) || field
  end

csv_options = {
  converters: [number_converter, time_converter],
  headers: :first_row
}

CSV.foreach(file_path, csv_options) do |row|
  row.each { |key, datum| p datum }
end
