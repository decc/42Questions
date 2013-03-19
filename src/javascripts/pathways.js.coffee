# This variable contains the current code as an array
# This is called by jQuery when the DOM is ready. 
# It reads the current settings from the URL and then 
# triggers a request for the data relating to that question.
$(document).ready () ->
  setupImplications()
  setVariablesFromURL()
  setupNextPreviousButtons()

# We need to keep track of the current pathway and the current question
window.code = "10111111111111110111111001111110111101101101110110111".split("")
question_name = "welcome"

# When the page is first loaded, checks its url and uses it to define
# the state of the visualisation. The url is expected to be of the form
# /code/question_name
setVariablesFromURL = () ->
  url_elements = window.location.pathname.split('/')
  window.code = url_elements[1].split("") if url_elements[1]
  question_name = url_elements[2] if url_elements[2]
  $(document)
    .trigger('pathwayChanged')
    .trigger('questionChanged')

# This is used to change which question we are viewing on screen.
# It sends a request for the description of the question to the server.
# When received this fragment is put on screen and then the implications 
# of the different levels are requested from the server.
# FIXME: Need a busy spinner
loadQuestion = () ->
  $.get("/question/#{question_name}.html", (data, status) ->
    if data?
      $("#question").html(data)
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

updown = (number) ->
  if number > 0
    "up #{number}"
  else if number < 0
    "down #{-number}"
  else
    "#{number}"


setupImplications = () ->
  #  Nowt

updateImplicationCallback = (data) ->
  window.data = data

  # Cost
  window.adjust_costs_of_pathway(data)
  low = Math.round(data.total_cost_low_adjusted)
  high = Math.round(data.total_cost_high_adjusted)
  if Math.abs(high-low) < 1
     cost = "£#{low}/person/year 2010-2050"
  else
     cost = "£#{low}&mdash;#{high}/person/year 2010-2050"
  $("#implications #cost").html("The average cost of this pathway is #{cost}")
 
  # Demand
  demand_change = Math.round(data.final_energy_demand["Total Use"][8] - data.final_energy_demand["Total Use"][0])
  $("#implications #demand").html("In this pathway, by 2050, energy demand #{updown(demand_change)} TWh/yr on 2010")

  # Supply
  supply_in_2050 = for k, v of data.primary_energy_supply
    { name: k, value: v[8] }

  supply_in_2050 = supply_in_2050.sort( (a,b) -> b.value - a.value )
  total = supply_in_2050[0].value
  words = for fuel in supply_in_2050.slice(1,4)
    "#{fuel.name}: #{Math.round(fuel.value * 100.0 / total)}%"

  $("#implications #supply").html("Main primary fuels: #{words.join(" ")}<br/>")

  # Emissions
  ghg = data.ghg.percent_reduction_from_1990
  $("#implications #emissions").html("Greenhouse gas emissions #{updown(-ghg)}% on 1990")
  
  
  # target = $("#implications")
  # target.empty()
  # window.adjust_costs_of_pathway(data)
  # low = Math.round(data.total_cost_low_adjusted)
  # high = Math.round(data.total_cost_high_adjusted)
  # if Math.abs(high-low) < 1
  #   cost = "£#{low}/person/year 2010-2050"
  # else
  #   cost = "£#{low}&mdash;#{high}/person/year 2010-2050"
  # target.append("Greenhouse gas emissions fall #{ghg}% 1990-2050. <br/>Costs average #{cost}.")

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
  console.log target
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
      target.find(".trajectory").removeClass("highlight")
      target.find(trajectoryClass(trajectory)).addClass("highlight")

      # Notify that the implications need updating
      $(document).trigger('pathwayChanged')

  chooseTrajectory = (new_trajectory) ->
    () ->
      # Set the code
      trajectory = new_trajectory
      for s, i in sectors
        window.code[s] = trajectory[i]
    
      selected = target.find(trajectoryClass(trajectory))

      # Update the CSS
      target.find(".trajectory").removeClass("highlight")
      target.find(".trajectory").removeClass("chosen")
      selected.addClass("chosen")

      # Briefly highlight the selected node
      d3.selectAll(selected)
        .style('background-color','#ff7259')
        .transition()
        .duration(1000)
        .style('background-color','#f3dc00')
        .each('end', () -> d3.select(@).style('background-color',null))

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
    target.find(trajectoryClass(trajectory)).addClass("highlight")

    # Now setup all the controls
    for possible_trajectory in combinations(possibleTrajectories)
      target.find(trajectoryClass(possible_trajectory))
          .hover( highlight(possible_trajectory), unHighlight(possible_trajectory) )
          .click( chooseTrajectory(possible_trajectory) )

  setupQuestion()

question_sequence = [
  'welcome'
  'nuclear'
  'ccs'
  'offshoreWind'
  'solarPV'
  'residentialHeating'
]

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
