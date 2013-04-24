

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$}) 
  watch(%r{^lib/(.+)\.rb$})   { "spec" } # { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^lib/(.+)\.treetop$})   { "spec" }
  watch(%r{^lib/(.+)\.csv$})   { "spec" }
  watch(%r{^spec/(.+)\.txt$})   { "spec" }
  #watch(%r{^spec/support/(.+)\.rb$})   { "spec" }
  watch('spec/spec_helper.rb')  { "spec" }
end





