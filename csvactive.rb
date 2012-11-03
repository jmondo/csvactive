#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

require 'csv'
require 'chronic'
require 'active_record'
require 'yaml'
require 'pry-debugger'

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

  DATA_TYPES = {
    "String" => :text,
    "Float" => :float,
    "Time" => :datetime
  }

  def initialize(file_path)
    @file_path = file_path
  end

  def csv
    @csv ||= CSV.open(@file_path, 'rb', CSV_OPTIONS)
  end

  def column_types
    @column_types ||= csv.shift.to_hash.each_with_object({}) do |(header, value), hash|
      hash[convert_to_column_name(header)] = DATA_TYPES[value.class.to_s]
    end
  end

  def column_name_syms
    @column_name_syms ||= csv.shift.to_hash.each_with_object({}) do |(header, value), hash|
      hash[header] = convert_to_column_name(header)
    end
  end

  protected

  def convert_to_column_name(string)
    string.gsub(' ','_').downcase
  end
end

class CreateThings < ActiveRecord::Migration
  def up
    create_table :things do |t|
      @@csv_parser.column_types.each do |title, type|
        t.column title, type
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
