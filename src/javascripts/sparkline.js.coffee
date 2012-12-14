window.sparkline = (args) ->
  # Attributes
  target = args.target # The id of the element to put this in
  width = args.width || 100
  height = args.height || width / 4
  x_entries = args.x_entries || 9
  last = x_entries-1
  y_max = args.y_max || 800
  speed = args.speed || 1000
  x_margin = args.x_margin || 30
  y_margin = args.y_margin || 5
  label_format = args.label_format || "0.0f"
  start_x_label = args.start_x_label || "2010"
  end_x_label = args.end_x_label || "2050"

  # Set up the drawing surface
  r = Raphael(args.target, width, height)

  # Set up the axes
  x = d3.scale.linear()
        .domain([0,last])
        .range([x_margin,width-x_margin])
  y = d3.scale.linear()
        .domain([0,y_max])
        .range([height-y_margin,y_margin])

  # Set up the data to line conversion
  line = d3.svg.line()
        .x( (d,i) -> x(i) )
        .y( (d,i) -> y(d) )
        .interpolate('basis')

  # Set up the number to label conversion
  label = d3.format(label_format)

  # Initialize all the variables
  path = undefined
  start_text = undefined
  end_text = undefined
  start_circle = undefined
  end_circle = undefined
  
  draw = (data) ->
    path = r.path(line(data))
    start_circle = r.circle(x(0),y(data[0]),2).attr({fill:'#000'})
    end_circle = r.circle(x(last),y(data[last]),2).attr({fill:'#000'})
    start_text = r.text(x(0)-5,y(data[0]),label(data[0])).attr({'text-anchor':'end'})
    end_text = r.text(x(last)+5,y(data[last]),label(data[last])).attr({'text-anchor':'start'})

    r.text(x(0),y(0)+3,"2010").attr({'font-size':7})
    r.text(x(last),y(0)+3,"2050").attr({'font-size':7})

  update = (data) ->
    path.animate({path: line(data)},speed)
    start_circle.animate({cy:y(data[0])},speed)
    end_circle.animate({cy:y(data[last])},speed)
    start_text.attr({text: label(data[0])})
    start_text.animate({y:y(data[0])},speed)
    end_text.attr({text: label(data[last])})
    end_text.animate({y:y(data[last])},speed)

  (data) ->
    if path?
      update(data)
    else
      draw(data)
