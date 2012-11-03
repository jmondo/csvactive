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
class CSVParser
  FLOAT_REGEX = /^(?<neg>[\(-]?)\$?(?<val>\.?\d[\d,\.]*)(?<perc>%?)\)?\s*$/
  NUMBER_CONVERTER =
    proc do |field|
      match = FLOAT_REGEX.match(field)
      if match
        field = match[:val].to_f
        field *= -1 if !match[:neg].empty?
        field /= 100 if !match[:perc].empty?
      end
      field
    end

  TIME_CONVERTER =
    proc do |field|
      Chronic.parse(field) || field
    end

  CSV_OPTIONS = {
    converters: [NUMBER_CONVERTER, TIME_CONVERTER],
    headers: :first_row,
    return_headers: false,
    encoding: 'UTF-8'
  }

  def initialize(file_path)
    @file_path = file_path
  end

  def csv
    @csv ||= CSV.open(@file_path, 'rb', CSV_OPTIONS)
  end

  def column_types
    unless @column_types
      @columns_types = csv.shift.to_hash
      @columns_types.each do |header, value|
        @columns_types[header] = value.class.to_s
      end
    end
  end
end

class CreateThings < ActiveRecord::Migration
  DATA_TYPES = {
    "String" => :text,
    "Float" => :float,
    "Time" => :datetime
  }
  def up
    create_table :things do |t|
      @@csv_parser.column_types.each do |title, type|
        t.column title.gsub(' ','_').downcase, DATA_TYPES[type]
      end
    end
  end
end

class Thing < ActiveRecord::Base
  def self.import_data
    @@csv_parser.csv.each do |row|
      attributes = {}
      row.to_hash.each do |header, value|
        attributes[header.gsub(' ','_').downcase] = value
      end
      create!(attributes)
    end
  end
end

file_path = ARGV[0]
raise 'you need to pass a csv to import' unless file_path

%x( rm ./data.sqlite3 )
@@csv_parser = CSVParser.new(file_path)

CreateThings.migrate(:up)
Thing.import_data

binding.pry

# exit to finish
