$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'nested_file'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.fail_fast = true
end

class FileStub
  fattr(:files) { {} }
  def add(file,contents)
    self.files[file] = contents
  end
  def exist?(file)
    !!files[file]
  end
  def read(file)
    files[file] || (raise "no file")
  end
  def entries(dir)
    dir = dir[0..-2] if dir[-1..-1] == '/'
    fs = files.keys.select { |x| File.dirname(x) == dir }.map { |x| File.basename(x) }

    res = []
    files.keys.each do |file|
      if file =~ /^#{dir}\/(.+)\//
        res << $1
      end
    end
    fs + res
  end
  def glob(glob)
    if glob == "/c/d/*.txt"
      entries("/c/d").map { |x| "/c/d/#{x}" }
    else
      raise "can't glob"
    end
  end

  def stub!
    FileTest.stub(:exist?) { |file| exist?(file) }
    File.stub(:read) { |file| read(file) }
    Dir.stub(:entries) do |dir|
      entries(dir)
    end

    Dir.stub(:[]) do |glob|
      glob(glob)
    end

    File.stub(:create) do |filename,body|
      add filename, body
    end
  end
end

shared_context "file stub" do
  let(:file_stub) do
    FileStub.new
  end

  before(:each) do
    file_stub.stub!
  end
end