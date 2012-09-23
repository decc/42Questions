files = Dir['*.haml']
files.delete_if { |f| f !~ /_question\d+/ }

files.each do |file|
  text = IO.readlines(file).join
  text.gsub!(/= *structured_results +\d+ *\n/i,'')
  text.gsub!(/= *image_tag *('[^']*')/i) do |tag|
    url = $1.gsub('structuredQuestions','/images')
    "%img{src:#{url}}"
  end
  puts text
  File.open(file,'w') { |f| f.puts text }
end
