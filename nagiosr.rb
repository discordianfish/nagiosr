#!/usr/bin/env ruby

require 'rubygems'
require 'sinatra'
require 'nagios_analyzer'
require 'json'
require 'csv'

STATUS_FILE = '/var/cache/nagios3/status.dat'
COMMAND_FILE = '/var/lib/nagios3/rw/nagios.cmd'


commands = []

set :erb, :trim => '-'
set :bind, '0.0.0.0'
helpers do
  def get_status(items, selector)
    puts "doing stuff with #{items}"
    status = NagiosAnalyzer::Status.new(STATUS_FILE, :include_ok => true)
    unless status.respond_to?(items, params.keys)
      raise Exception, "status.#{items} is invalid"
    end
  
    status.send(items).map do |item|
      item.hash.select {|k,v| selector ? selector.include?(k) : true}
    end
  end
end

get '/status/?:items?.json' do
  items = params[:items] || 'items'
  content_type :json
  self.get_status(items, params).to_json
end


get '/status/?:items?.csv' do
  items = params[:items] || 'items'
  content_type :text

  status = get_status(items, params.keys)
  header = status.first.keys
  
  [ CSV.generate_line(header), *status.map {|s| CSV.generate_line(s.values)} ].join("\n")
end