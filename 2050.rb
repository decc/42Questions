require 'sinatra'
require 'decc_2050_model'
require 'json'

enable :lock # The C 2050 model is not thread safe

get '/' do 
  redirect to("/1111111111111111111111111111111111111111111111111111/0")
end

get %r|/(_question\d+.html)|, :provides => :html do |question|
  haml "#{question}".to_sym
end

get '/:id', :provides => :json do |id|
  last_modified Decc2050Model.last_modified_date # Don't bother recalculating unless the model has changed
  expires (24*60*60), :public # cache for 1 day
  content_type :json # We return json
  Decc2050ModelResult.calculate_pathway(id).to_json
end

# This has the methods needed to dynamically create the view
if development?
  require 'haml'

  set :views, settings.root + '/src'

  get '*' do
    load './src/helper.rb'
    helpers(Helper)
    haml :'index.html'
  end
else
  get '*' do 
    send_file 'public/index.html'
  end
end
