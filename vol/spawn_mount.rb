require 'mharris_ext'

puts "You can also put forked code in a block pid: #{Process.pid}"
pid = fork do
  puts "Hello from fork pid: #{Process.pid}"
  File.create("fork.pid",Process.pid)
  num = rand(10000000000)
  ec "mkdir tmp/test#{num}"
  cmd = "bundle exec ruby ./bin/nested_file /code/orig/nested_file/tmp/test_parent /code/orig/nested_file/tmp/test#{num}"
  puts cmd
  exec cmd
end
puts "The parent process just skips over it: #{Process.pid}"
# 20.times do |i|
#   puts "Parent times #{i}"
#   sleep 1
# end
Process.wait pid

