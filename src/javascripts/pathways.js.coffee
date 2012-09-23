# This variable contains the current code as an array
code = "1111111111111111111111111111111111111111111111111111".split("")
# This variable contains the current question number as an integer
question = 0
# This variable contains the current level for that question as an integer
level = 0
# This hash contains the implicaitons of the current pathway (e.g., cost, energy flows)
implications = {}

# This updates the implications hash to contain the implications of the pathway passed
# to it as an argument. It is asyncronous, and calls update() when it gets a result.
getImplications = (c = code.join("")) ->
  $.getJSON("/#{c}", (data, status) ->
    if data?
      implications = data
      update()
  )

getQuestion = (number=question) ->
  $.get("/_question#{number}", (data, status) ->
    if data?
      $('#onepage').html(data)
      setUpEvents()
      highlightChoice()
  )

setup = () ->
  setVariablesFromURL()
  getQuestion()

setUpEvents = () ->
  for possible_level in [1..4]
    $("#choice#{possible_level}").click(setLevelCallback(possible_level))
    false

setLevelCallback = (possible_level) ->
  () -> setLevel(possible_level)

setLevel = (new_level) ->
  unHighlightChoice()
  level = new_level
  code[question] = level
  highlightChoice()
  getImplications()

setQuestion = (new_question) ->
  question = new_question
  level = code[question]
  getQuestion()

window.setQuestion = setQuestion


update = () ->
  $('#ghg_implication').html(implications.ghg.percent_reduction_from_1990)
  window.adjust_costs_of_pathway(implications)
  low = Math.round(implications.total_cost_low_adjusted)
  high = Math.round(implications.total_cost_high_adjusted)
  if Math.abs(high-low) < 1
    cost = "£#{low}/person/year 2010-2050"
  else
    cost = "£#{low}&mdash;#{high}/person/year 2010-2050"
  $('#cost_implication').html(cost)
  console.log implications

$(document).ready () ->
  setup()
  getImplications()

# When the page is first loaded, checks its url and uses it to define
# the state of the visualisation
setVariablesFromURL = () ->
  url_elements = window.location.pathname.split('/')
  code = url_elements[1].split("")
  question = url_elements[2]
  level = code[question]

# Highlights the current choice (level 1, 2, 3, or 4) on the screen
highlightChoice = () ->
  $("#choice#{level}").addClass("chosen")

# Unhighlights the current choice (level 1, 2, 3, or 4) on the screen
unHighlightChoice = () ->
  $("#choice#{level}").removeClass("chosen")
