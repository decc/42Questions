cost_override_in_place_warning = () ->
  for own name, ignore of cost_categories
    o = jQuery.jStorage.get(name,undefined)
    if o? && o != 'point'
      $('#cost_override_warning').show()
      break

adjust_costs_of_pathway = (pathway) ->
  total = { low: 0, range: 0, high: 0, finance_max:0}
  for own name,values of pathway.cost_components
    # console.log name, values if name == "Conventional thermal plant"
    #unless name == 'Finance cost'
    fraction_of_width = jQuery.jStorage.get(name,null)
    # Check if someone has set a preference
    if fraction_of_width? && fraction_of_width != 'point' && fraction_of_width != 'uncertain'
      cost = values.low + (values.range * fraction_of_width)
      finance = values.finance_low + (values.finance_range * fraction_of_width)
      
      values.low_adjusted = cost
      values.range_adjusted = 0
      values.high_adjusted = cost
      
      values.finance_low_adjusted = finance
      values.finance_range_adjusted = 0
      values.finance_high_adjusted = finance
    
    # Check if someone has specified that the cost should be left uncertain
    else if fraction_of_width == 'uncertain'
      values.low_adjusted = values.low
      values.range_adjusted = values.range
      values.high_adjusted = values.high
      values.finance_low_adjusted = values.finance_low
      values.finance_range_adjusted = values.finance_range
      values.finance_high_adjusted = values.finance_high
      
    # Otherwise use the point estimate
    else 
      values.low_adjusted = values.point
      values.range_adjusted = 0
      values.high_adjusted = values.point
      
      implied_fraction_of_width = (values.point-values.low)/values.range
      finance = values.finance_low + (values.finance_range * implied_fraction_of_width)
      
      values.finance_low_adjusted = values.finance
      values.finance_range_adjusted = 0
      values.finance_high_adjusted = values.finance
    
    total.low += values.low_adjusted
    total.range += values.range_adjusted
    total.high += values.high_adjusted
    total.finance_max += values.finance_high_adjusted
        
  # finance_fraction_of_width = jQuery.jStorage.get("Finance cost",null)
  # finance_component = pathway.cost_components['Finance cost']
  # if finance_fraction_of_width? && fraction_of_width != 'point' && fraction_of_width != 'uncertain'
  #   finance_cost = finance_fraction_of_width * total.finance_max
  #   
  #   finance_component.low_adjusted = finance_cost
  #   finance_component.range_adjusted = 0
  #   finance_component.high_adjusted = finance_cost    
  # else if fraction_of_width == 'uncertain'
  #   finance_component.low_adjusted = 0
  #   finance_component.range_adjusted = total.finance_max
  #   finance_component.high_adjusted = total.finance_max
  # else
  #   finance_component.low_adjusted = 
  # 
  # total.low += finance_component.low_adjusted
  # total.range += finance_component.range_adjusted
  # total.high += finance_component.high_adjusted
  
  pathway.total_cost_low_adjusted = total.low
  pathway.total_cost_range_adjusted = total.range
  pathway.total_cost_high_adjusted = total.high
  pathway

setDefaultStoreIfRequired = (pathway) ->
  return false if jQuery.jStorage.get('defaultCostsSet') == true
  for own name, values of pathway.cost_components
    jQuery.jStorage.set(name,0) if ( (name != 'Oil') && (name != 'Gas') && (name != 'Coal') && (name != 'Finance cost'))
  jQuery.jStorage.set('defaultCostsSet',true)

calculateIncrementalCost = (pt,pc) ->
  adjust_costs_of_pathway(pt) unless pt.total_cost_low_adjusted?
  adjust_costs_of_pathway(pc) unless pc.total_cost_low_adjusted?
  # tt = value of t when looking for lowest cost for t
  # tc = value of t when looking for lowest cost for c
  # ct = value of c when looking for lowest cost for t
  # cc = value of c when looking for lowest cost for c
  tt = 0
  tc = 0
  ct = 0
  cc = 0
  for own name, tvalues of pt.cost_components
    unless name == 0
      cvalues = pc.cost_components[name]
      # Doesn't matter for relative size, add value to all
      if tvalues.range_adjusted == cvalues.range_adjusted
        tt += tvalues.low_adjusted
        tc += tvalues.low_adjusted
        ct += cvalues.low_adjusted
        cc += cvalues.low_adjusted
      else if tvalues.range_adjusted >= cvalues.range_adjusted # t is more uncertain than c
        # best for t will be if take low values for both
        tt += tvalues.low_adjusted
        ct += cvalues.low_adjusted
        # best for c will be if take high values for both
        tc += tvalues.high_adjusted
        cc += cvalues.high_adjusted
      else # c is more uncertain than t
        # best for t will be if take high values for both
        tt += tvalues.high_adjusted
        ct += cvalues.high_adjusted
        # best for c will be if take low values for both
        tc += tvalues.low_adjusted
        cc += cvalues.low_adjusted
  {tc: tc, tt: tt, cc: cc, ct: ct}

direction = (value) ->
  return "more expensive" if value > 0
  "cheaper"

window.incremental_cost_in_words = (p, c) ->
    i = calculateIncrementalCost(p,c)
    i1 = i.tc - i.cc
    i2 = i.tt - i.ct
    if i1 == i2
      "£#{Math.round(Math.abs(i1))}/person/year #{direction(i1)}"
    else
      "£#{Math.round(Math.abs(i2))}/person/year #{direction(i2)} and £#{Math.round(Math.abs(i1))}/person/year #{direction(i1)}"
  

window.adjust_costs_of_pathway = adjust_costs_of_pathway
window.calculateIncrementalCost = calculateIncrementalCost
window.cost_override_in_place_warning = cost_override_in_place_warning
