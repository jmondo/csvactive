#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'chronic'
require 'active_record'
require 'yaml'
require 'pry'

dbconfig = YAML::load(File.open('database.yml'))
ActiveRecord::Base.establish_connection(dbconfig)

# integers, currency, percents (truncate)
# TODO: phone numbers!
FLOAT_REGEX = /^(?<neg>[\(-]?)\$?(?<val>\.?\d[\d,\.]*)(?<perc>%?)\)?\s*$/
DATA_TYPES = {
  "String" => :text,
  "Float" => :float,
  "Time" => :datetime
}

file_path = ARGV[0]
raise 'you need to pass a csv to import' unless file_path

number_converter =
  proc do |field|
    match = FLOAT_REGEX.match(field)
    if match
      field = match[:val].to_f
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
  headers: :first_row,
  return_headers: false,
  encoding: 'UTF-8'
}

@@csv_array = CSV.open(file_path, 'rb', csv_options).to_a
@@columns_types = @@csv_array.first.to_hash
@@columns_types.each do |header, value|
  @@columns_types[header] = value.class.to_s
end

%x( rm ./data.sqlite3 )

class CreateThings < ActiveRecord::Migration
  def up
    create_table :things do |t|
      @@columns_types.each do |title, type|
        t.column title.gsub(' ','_').downcase, DATA_TYPES[type]
      end
    end
  end
end

CreateThings.migrate(:up)

class Thing < ActiveRecord::Base
  def self.import_data
    @@csv_array.each do |row|
      attributes = {}
      row.to_hash.each do |header, value|
        attributes[header.gsub(' ','_').downcase] = value
      end
      create!(attributes)
    end
  end
end

Thing.import_data

binding.pry
