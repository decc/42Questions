# encoding: utf-8
module Helper

  def structure
    ModelStructure.instance
  end

  def stylesheet
    "<link href='/assets/#{assets['application.css'] || 'application.css'}' media='screen' rel='stylesheet' type='text/css' />"
  end

  def javascript
    "<script src='/assets/#{assets['application.js'] || 'application.js'}' type='text/javascript'></script>"
  end

  def choices(c)
    { data: { choice: Hash[c.map { |k,v| [k.downcase.gsub(/[^A-Za-z0-9]+/,'-'), v] }] } }
  end

  def assets
    @assets ||= {}
  end

  def assets=(h)
    @assets = h
  end

end
