# encoding: utf-8
require 'rubygems'
require 'bundler'
Bundler.setup

require './2050'
require 'sprockets'
require './src/helper'

ENV['RACK_ENV'] = ENV['RAILS_ENV'] if ENV['RAILS_ENV']

map '/' do
  use Rack::CommonLogger
  map '/assets' do
    environment = Sprockets::Environment.new

    environment.append_path 'src/javascripts'
    environment.append_path 'src/stylesheets'
    environment.append_path 'public/assets'
    environment.append_path 'contrib/js'
    environment.append_path 'contrib/css'
    environment.append_path 'contrib/img'

    environment.context_class.class_eval do 
      include Helper
    end

    run environment
  end

  run Sinatra::Application
end
