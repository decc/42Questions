# This is our preferred web framework
require 'sinatra'

# This is the code that actually does the calculating
require 'decc_2050_model'

# We return data to the Javascript using json
require 'json'

# These are our prefered templating languages
require 'haml' # For HTML
require 'sass' # For CSS
require 'coffee_script' # For Javascript

enable :lock # The C 2050 model is not thread safe

# By default we take people to a blank pathway with the first question
get '/' do 
  redirect to("/1111111111111111111111111111111111111111111111111111/nuclear")
end

# This is called by the page Javascript to return a fragment of html for each question
get '/question/:question_name', :provides => :html do |question_name|
  haml "question/#{question_name}".to_sym
end

# This is called by the page Javascript to get the results for a particular pathway
get '/:id', :provides => :json do |id|
  last_modified Decc2050Model.last_modified_date # Don't bother recalculating unless the model has changed
  expires (24*60*60), :public # cache for 1 day
  content_type :json # We return json
  Decc2050ModelResult.calculate_pathway(id).to_json
end

# This has the methods needed to dynamically create the views
# In development mode we compile the HAML templates to HTML on the fly
# in production mode we expect them to have already been precompiled
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
