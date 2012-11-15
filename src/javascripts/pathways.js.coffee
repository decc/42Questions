# This variable contains the current code as an array
code = "1111111111111111111111111111111111111111111111111111".split("")
# This variable contains the current question number as an integer
question = 0
# This variable contains the current level for that question as an integer
level = 0

# This array contains the implications of the different levels for the current question
implications_of_different_levels = [undefined, undefined, undefined, undefined]

# This sends 4 requests to the server for the implications of chosing different
# levels for the current question.
getAllImplications = (c = code) ->
  for possible_level in [1..4]
    c[question] = possible_level
    $.getJSON("/#{c.join("")}", (data, status) ->
      if data?
        updateImplications(data)
    )
    false

# This is the callback for when the data about a particular level is received
# it stores the data and then updates the relevant piece of text onscreen
updateImplications = (data) ->
  possible_level = data.choices[question]
  implications_of_different_levels[possible_level-1] = data
  updateImplicationTextForLevel(possible_level)

# This updates all the implications text onscreen, wihtout requesting further
# data from the server. This is called when the user selects a different level
updateImplicationTextForAllLevels = () ->
  for possible_level in [1..4]
    updateImplicationTextForLevel(possible_level)

# This flag is needed in case the data for the selected level
# arrives after the data for other levels. This flag indicates
# that the relative costs and emissions will need to be calculated
# when the chosen level data arrives.
flag_implication_for_later_update = false

# This writes out the implications (greenhouse gas emissions, cost)
# of chosing a particular level.
updateImplicationTextForLevel = (possible_level) ->
  target = $("#choice#{possible_level} .performance")
  target.empty()
  data = implications_of_different_levels[possible_level - 1]
  return unless data?
  if parseInt(level) == possible_level # We are explaining the implications of the selected level, so use absolute values
    ghg = data.ghg.percent_reduction_from_1990
    window.adjust_costs_of_pathway(data)
    low = Math.round(data.total_cost_low_adjusted)
    high = Math.round(data.total_cost_high_adjusted)
    if Math.abs(high-low) < 1
      cost = "£#{low}/person/year 2010-2050"
    else
      cost = "£#{low}&mdash;#{high}/person/year 2010-2050"
    target.append("Greenhouse gas emissions fall #{ghg}% 1990-2050. <br/>Costs average #{cost}.")
    if flag_implication_for_later_update
      flag_implication_for_later_update = false
      updateImplicationTextForAllLevels()
  else # We are explaning the implications of a different level, so we use values relative to the chosen level
    chosen_level_data = implications_of_different_levels[level-1]
    unless chosen_level_data?
      flag_implication_for_later_update = true
      return
    ghg_delta = data.ghg.percent_reduction_from_1990 - chosen_level_data.ghg.percent_reduction_from_1990
    if ghg_delta < 0
      ghg_message = "higher"
    else
      ghg_message = "lower"
    target.append("Greenhouse gas emissions #{Math.abs(ghg_delta)} percentage points #{ghg_message} in 2050 compared with level #{level}. <br/>Averages #{window.incremental_cost_in_words(data, chosen_level_data)} than level #{level}.")
  
# This is used to change which question we are viewing on screen.
# It sends a request for the description of the question to the server.
# When received this fragment is put on screen and then the implications 
# of the different levels are requested from the server.
getQuestion = (number=question) ->
  implications_of_different_levels = [undefined, undefined, undefined, undefined]
  $.get("/_question#{number}", (data, status) ->
    if data?
      $('#onepage').html(data)
      document.title = $("h1").html()
      getAllImplications()
      setUpEvents()
      highlightChoice()
  )


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
  updateImplicationTextForAllLevels()
  pushState()
  false

setQuestion = (new_question) ->
  question = new_question
  level = code[question]
  getQuestion()
  pushState()
  false

window.setQuestion = setQuestion

pushState = () ->
  return false unless history && history['pushState']?
  history.pushState(code,code,"/#{code.join("")}/#{question}")
  
window.onpopstate = (event) ->
  setVariablesFromURL()
  getQuestion()

window.previousQuestion = () ->
  moveAlongQuestionSequence(-1)

window.nextQuestion = () ->
  moveAlongQuestionSequence(+1)

# This is used by the forward and back buttons at the bottom of each
# page to allow the user to move along the sequence defined in
# window.question_sequence
moveAlongQuestionSequence = (delta) ->
  sequence = window.question_sequence
  position_in_sequence = sequence.indexOf(parseInt(question)) + delta
  position_in_sequence = 0 if position_in_sequence >= sequence.length
  position_in_sequence = sequence.length - 1 if position_in_sequence < 0
  setQuestion(sequence[position_in_sequence])

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
  $(".showChoice#{level}").show()

# Unhighlights the current choice (level 1, 2, 3, or 4) on the screen
unHighlightChoice = () ->
  $("#choice#{level}").removeClass("chosen")
  $(".showChoice#{level}").hide()

# This is called by jQuery when the DOM is ready. 
# It reads the current settings from the URL and then 
# triggers a request for the data relating to that question.
$(document).ready () ->
  setVariablesFromURL()
  getQuestion()
