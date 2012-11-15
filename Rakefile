#!/usr/bin/env rake
# coding: utf-8
require 'sprockets'
require 'rake/sprocketstask'
require './src/helper'

# This deals with the javascript and css
Rake::SprocketsTask.new do |t|
  environment = Sprockets::Environment.new
  environment.append_path 'src/javascripts'
  environment.append_path 'src/stylesheets'
  environment.append_path 'contrib/js'
  environment.append_path 'contrib/css'
  environment.append_path 'contrib/img'

  environment.context_class.class_eval do 
    include Helper
  end

  t.environment = environment
  t.output      = "./public/assets"
  t.assets      = %w( application.js application.css )
end



require 'haml'
require 'json'
require 'decc_2050_model'
require_relative 'src/helper'

manifest = './public/assets/manifest.json'
file manifest => ['assets']  

desc "Compiles changes to src/*.haml into public/ and adds links it to the latest versions of application.cs and application.js"
task 'html' => [manifest] do 

  class Context
    include Helper
  end

  context = Context.new

  # We need to figure out the filename of the latest javascript and css
  context.assets = JSON.parse(IO.readlines(manifest).join)['assets']

  haml_files = Dir.glob("./src/*.haml")
  haml_files.each do |name|
    p "Compiling #{name}"
    input = IO.readlines(name).join
    File.open("./public/"+name[/\.\/src\/(.*)\.haml/,1],'w') do |f|
      f.puts Haml::Engine.new(input).render(context)
    end
  end
end


