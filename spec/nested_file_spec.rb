require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

def try_for_period(sec)
  start = Time.now
  while (Time.now-start) < sec
    begin
      return yield
    rescue => exp
      #puts "failed, elapsed #{Time.now-start}"
      sleep(0.05)
    end
  end
  raise 'reached end'
  yield
end

describe "NestedFile" do
  it 'smoke' do
    2.should == 2
  end

  let(:parent_dir) { "#{NestedFile.tmp_dir}/test_parent" }
  let(:child_dir) { "#{NestedFile.tmp_dir}/test" }

  def create_parent_file(path,str)
    try_for_period(2) do
      File.create "#{parent_dir}/#{path}",str
    end
  end

  def create_child_file(path,str)
    try_for_period(2) do
      File.create "#{child_dir}/#{path}",str
    end
  end

  before(:each) do
    FileUtils.mkdir(parent_dir) unless FileTest.exist?(parent_dir)
    `rm -rf #{parent_dir}/*`
    Dir["spec/parent_template/*"].each do |f|
      `cp -r #{f} #{parent_dir}`
    end

    Dir["#{parent_dir}/**/*.txt"].each do |file|
      body = File.read(file).gsub("{{NF_ROOT}}",NestedFile.root)
      File.create file, body
    end
  end

  it 'read from mounted fs' do
    str = File.read "#{child_dir}/a.txt"
    str.should == "hello"
  end

  it 'read subs in file contents - full path' do
    str = File.read "#{child_dir}/include_others.txt"
    str.should == "<file #{parent_dir}/a.txt>\nhello\n</file>"
  end

  it 'read subs in file contents - relative_path' do
    str = File.read "#{child_dir}/include_others_rel.txt"
    str.should == "<file a.txt>\nhello\n</file>"
  end

  describe "can use glob in file desc" do
    before do
      create_parent_file "sub/a.txt","abc" 
      create_parent_file "sub/b.txt","xyz" 
      create_parent_file "sub_all.txt","<files sub/*.txt></files>"
    end

    it 'shows group' do
      exp = ['<files sub/*.txt>']
      exp += ['<file sub/a.txt>','abc','</file>']
      exp += ['<file sub/b.txt>','xyz','</file>']
      exp << "</files>"
      File.read("#{child_dir}/sub_all.txt").should == exp.join("\n")
    end
  end

  describe "nested body not saved to parent" do
    before do
      create_child_file "d.txt","<file e.txt>data</file>"
    end
    it 'e is data' do
      File.read("#{parent_dir}/e.txt").should == "data"
    end
    it "d.txt doesn't have body" do
      File.read("#{parent_dir}/d.txt").should == "<file e.txt>\n</file>"
    end
  end

  if false
  describe 'saving file with sections writes to other files' do
    before(:each) do
      body = "<file #{parent_dir}/c.txt>\nI was here\n</file>"
      create_child_file "b.txt",body
    end

    it 'exists' do
      FileTest.should be_exist("#{parent_dir}/b.txt")
      FileTest.should be_exist("#(child_dir}/b.txt")
      FileTest.should be_exist("#{parent_dir}/c.txt")
      FileTest.should be_exist("#(child_dir}/c.txt")
    end

    it 'c.txt has written text' do
      File.read("#(parent_dir}/c.txt").should == "I was here"
    end

  end

  describe 'saving file with sections writes to other files - relative path' do
    before(:each) do
      body = "<file c.txt>\nI was here\n</file>"
      create_child_file "b.txt", body
    end

    it 'exists' do
      FileTest.should be_exist("#{parent_dir}/b.txt")
      FileTest.should be_exist("#(child_dir}/b.txt")
      FileTest.should be_exist("#{parent_dir}/c.txt")
      FileTest.should be_exist("#(child_dir}/c.txt")
    end

    it 'c.txt has written text' do
      File.read("#{parent_dir}/c.txt").should == "I was here"
    end

  end

  describe 'saving file with sections writes to other files - save to sub' do
    before(:each) do
      body = "<file sub/z.txt>\nI was here\n</file>"
      create_child_file "b.txt", body
    end

    it 'z.txt has written text' do
      File.read("#{parent_dir}/sub/z.txt").should == "I was here"
    end
  end

  describe 'saving file with sections writes to other files - save to parent' do
    before(:each) do
      body = "<file ../p.txt>\nI was here\n</file>"
      create_child_file "sub/b.txt", body
    end

    it 'z.txt has written text' do
      File.read("#{parent_dir}/p.txt").should == "I was here"
    end
  end



  describe "don't overwrite existing" do
    before do
      create_parent_file "exist.txt","Hello" 
      create_child_file "summary.txt","<file exist.txt></file>"
    end

    it 'leaves exist.txt alone' do
      File.read("#{parent_dir}/exist.txt").should == 'Hello'
    end
  end
  end

end
