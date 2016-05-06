require 'mharris_ext'

# res = ec("ps -ax")
# lines = res.split("\n").map { |line| line[25..-1] }
# puts lines.sort.join("\n")

# (1..23).each do |i|
#   ec "umount ruby@osxfuse#{i}"
# end

# mount listed the 24 mounts
# lsvfs showed 24

# ec "umount ruby@osxfuse0"
# ec "umount ruby@osxfuse88"
# ec "umount ruby@osxfuse2"

mounts = ec("mount").split("\n").map { |x| x.split(" ").first }.select { |x| x =~ /osxfuse/ }
puts mounts.inspect
mounts.each do |name|
  ec "umount #{name}"
end