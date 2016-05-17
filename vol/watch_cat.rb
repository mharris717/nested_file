def print_cat
  %w(test_dir child).each do |pc|
    %w(a.txt def.txt).each do |f|
      f = "#{pc}/#{f}"
      puts f.upcase
      puts File.read(f)
      puts "\n\n"
    end
  end
  puts "\n\n-------------------\n\n"
end

loop do
  print_cat
  sleep 1
end