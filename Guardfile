

# guard 'rspec' do
#   watch(%r{^spec/.+_spec\.rb$}) 
#   watch(%r{^lib/(.+)\.rb$})   { "spec" } # { |m| "spec/lib/#{m[1]}_spec.rb" }
#   watch(%r{^lib/(.+)\.treetop$})   { "spec" }
#   watch(%r{^lib/(.+)\.csv$})   { "spec" }
#   watch(%r{^spec/(.+)\.txt$})   { "spec" }
#   #watch(%r{^spec/support/(.+)\.rb$})   { "spec" }
#   watch('spec/spec_helper.rb')  { "spec" }
# end





guard("rspec", :all_on_start => true, :all_after_pass => false, :zeus => false, :cli => "--color --fail-fast", cmd: 'bundle exec rspec') do
  watch(%r{^spec/.+?_spec\.rb$})
  watch(%r{^lib/(.+?)\.rb$}) {|match| "spec/lib/#{match[1]}_spec.rb"}
  watch(%r{^app/models/(.+)\.rb}) {|match| "spec/models/#{match[1]}_spec.rb"}
  watch(%r{^app/controllers/(.+)\.rb}) {|match| "spec/controllers/#{match[1]}_spec.rb"}
  watch(%r{^app/emailer/(.+)\.rb}) {|match| "spec/emailer/#{match[1]}_spec.rb"}
  watch(%r{^app/mailer/messenger_mailer\.rb}) {|match| "spec/lib/jobs/messenger_emailer_spec.rb"}
end