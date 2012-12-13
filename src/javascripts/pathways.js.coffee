# This variable contains the current code as an array
# This is called by jQuery when the DOM is ready. 
# It reads the current settings from the URL and then 
# triggers a request for the data relating to that question.
$(document).ready () ->
  setupQuestionDivs()
  setupLayout()
  setVariablesFromURL()
  setupNextPreviousButtons()

# We need to keep track of the current pathway and the current question
window.code = "1111111111111111111111111111111111111111111111111111".split("")
question_name = "nuclear"

# In order to do the sideways scrolling trick, we need to know some layout things
window_width = undefined
question_margin = 100

# When the page is first loaded, checks its url and uses it to define
# the state of the visualisation. The url is expected to be of the form
# /code/question_name
setVariablesFromURL = () ->
  url_elements = window.location.pathname.split('/')
  window.code = url_elements[1].split("")
  question_name = url_elements[2]
  $(document)
    .trigger('pathwayChanged')
    .trigger('questionChanged')

# This is used to change which question we are viewing on screen.
# It sends a request for the description of the question to the server.
# When received this fragment is put on screen and then the implications 
# of the different levels are requested from the server.
# FIXME: Need a busy spinner
loadQuestion = () ->
  return false unless $("##{question_name}").html() == ''
  $.get("/question/#{question_name}.html", (data, status) ->
    if data?
      $("##{question_name}").html(data)
  )

$(document).on('questionChanged', () -> loadQuestion())

$(document).on('pathwayChanged', () -> data(window.code, updateImplicationCallback))

# This is the bit that gets the implications of a particular pathway
# it keeps copies of previous implications in a cache
# FIXME: Cache is a memory leak
cache = {}
data = (code, callback) ->
  callback(cache[code]) if cache[code]?
  $.getJSON("/#{code.join('')}", (data, status) ->
    if data?
      cache[code] = data
      callback(data)
  )

# We need to keep track of some implications
current_emissions_reduction = undefined
current_cost_low = undefined
current_cost_high = undefined

updateImplicationCallback = (data) ->
   target = $("#implications")
   target.empty()
   ghg = data.ghg.percent_reduction_from_1990
   window.adjust_costs_of_pathway(data)
   low = Math.round(data.total_cost_low_adjusted)
   high = Math.round(data.total_cost_high_adjusted)
   if Math.abs(high-low) < 1
     cost = "£#{low}/person/year 2010-2050"
   else
     cost = "£#{low}&mdash;#{high}/person/year 2010-2050"
   target.append("Greenhouse gas emissions fall #{ghg}% 1990-2050. <br/>Costs average #{cost}.")

$(document).on('choiceMade', () -> updateURL() )
$(document).on('questionChanged', () -> updateURL() )

# If the browser supports it, this updates the URL to match the chosen
# pathway and quesiton
updateURL = () ->
  return false unless history && history['pushState']?
  return false if history.state == code
  history.pushState(code,code,"/#{window.code.join("")}/#{question_name}")

# FIXME: This doesn't seem to work properly
window.onpopstate = () ->
   setVariablesFromURL()

# This takes an array of possible levels and returns
# all its possible combinations.
# e.g., combinations([4]) => [[1],[2],[3],[4]]
# e.g., combinations([4,2]) => [[1,1], [1,2], [2,1], ... [4,1], [4,2]]
combinations = (maximums, i = 0) ->
  if i >= (maximums.length-1)
    ([j] for j in [1..maximums[i]])
  else
    sub_combinations = combinations(maximums, i+1)
    combinations_at_this_level = []
    for level in [1..maximums[i]]
      for combination in sub_combinations
        c = combination.slice()
        c.unshift(level)
        combinations_at_this_level.push(c)
    combinations_at_this_level

# This creates all the callbacks for a 'standard' question
# the object passed as an argument should have:
# { 
#   sectors: [<sector number>, <optional subsequent sector number>]
#   numberOfPossibleTrajectories: [<number of possible trajectories for first sector>, ...]
# }
# It assumes that the web page has a series of items with class trajectory1, trajectory2 etc
window.standardQuestion = ( arg ) ->
  target = $("##{arg.id}")
  sectors = arg.sectors
  possibleTrajectories = arg.numberOfPossibleTrajectories
  trajectory = []

  # This returns a trajectory class for a particular trajectory
  trajectoryClass = (t) ->
    ".trajectory"+t.join('')

  highlight = (highlight_trajectory) ->
    () ->
      # Set the code
      for s, i in sectors
        window.code[s] = highlight_trajectory[i]

      # Update the CSS
      target.find(".trajectory").removeClass("highlight")
      target.find(trajectoryClass(highlight_trajectory)).addClass("highlight")

      # Notify that the implications need updating
      $(document).trigger('pathwayChanged')

  unHighlight = (highlight_trajectory) ->
    () ->
      # Set the code
      for s, i in sectors
        window.code[s] = trajectory[i]

      # Update the CSS
      target.find(trajectoryClass(highlight_trajectory)).removeClass("highlight")

      # Notify that the implications need updating
      $(document).trigger('pathwayChanged')

  chooseTrajectory = (new_trajectory) ->
    () ->
      # Set the code
      trajectory = new_trajectory
      for s, i in sectors
        window.code[s] = trajectory[i]
      
      # Update the CSS
      target.find(".trajectory").removeClass("highlight")
      target.find(".trajectory").removeClass("chosen")
      target.find(trajectoryClass(trajectory)).addClass("chosen")

      # Notify that the implication needs updating
      $(document).trigger('pathwayChanged')
      $(document).trigger('choiceMade')

  setupQuestion = () ->
    # Setup the title
    document.title = $("h1").html()

    # Figure out the current trajectory for the sectorss we care about
    for s, i in sectors
      trajectory[i] = window.code[s]
    
    # Make sure we display the correct trajectory onscreen
    chooseTrajectory(trajectory)()

    # Now setup all the controls
    for possible_trajectory in combinations(possibleTrajectories)
      target.find(trajectoryClass(possible_trajectory))
          .hover( highlight(possible_trajectory), unHighlight(possible_trajectory) )
          .click( chooseTrajectory(possible_trajectory) )

  setupQuestion()

question_sequence = [
  'nuclear'
  'ccs'
  'residentialHeating'
]

question_divs = undefined

setupQuestionDivs = () ->
  parent = $('#questions')
  for q in question_sequence
    parent.append("<div id='#{q}' class='question'></div>")
  question_divs = $('.question')

setupLayout = () ->
  window_width = $(document).width()
  $('#questions')
    .width(window_width)
    .height(1000)
    .append("<div style='position: absolute; width: #{question_margin}px; left: #{question_divs.length * window_width}px; top: 100px;'>&nbsp;</div>")
  question_divs
    .width(window_width-30-question_margin)
    .css('left', (i) -> (i*window_width) + (question_margin/2))
    .css('top', 100)

# FIXME: I don't get callbacks, why can't I pass the animateToQuestion function directly?
$(document).on('questionChanged', () -> animateToQuestion() )

animateToQuestion = () ->
  i = question_sequence.indexOf(question_name)
  $('#questions').animate(
    {scrollLeft: (i*window_width)}
    1000
  )

incrementQuestionBy = (increment) ->
  i = question_sequence.indexOf(question_name)
  i = i + increment
  i = question_sequence.length - 1 if i < 0
  i = 0 if i >= question_sequence.length
  question_name = question_sequence[i]
  $(document).trigger('questionChanged')

setupNextPreviousButtons = () ->
  $('#next_sector').click( (event) -> incrementQuestionBy(1); event.preventDefault() )
  $('#previous_sector').click( (event) -> incrementQuestionBy(-1); event.preventDefault() )
