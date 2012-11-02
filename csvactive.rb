#!/usr/bin/env ruby
require 'csv'
require 'chronic'

# integers, currency, percents (truncate)
regex = /^[\$]?(val:\d[\d,\.]*)[%]?\s*$/
# http://rubular.com/r/uR3TqossJC

# time, date
# Chronic.parse(value) # use mine

# strings
# use text

file_path = ARGV[0]
raise 'you need to pass a csv to import' unless file_path

number_converter =
  proc do |field|
    match = regex.match(field)
    match ? match[:val].to_f : field
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
