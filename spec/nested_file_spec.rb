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

def print_child_file_changes
  puts "print_child_file_changes"
  STDIN.gets
  before_files = Dir["#{child_dir}/**/*.txt"]
  yield
  after_files = Dir["#{child_dir}/**/*.txt"]
  both_files = (before_files+after_files).uniq

  puts "#{both_files} total files"
  both_files.each do |file|
    if [before_files,after_files].any? { |fs| !fs.include?(file) }
      puts "#{file} #{before_files.include?(file)}/#{after_files.include?(file)}"
    end
  end
end

describe "NestedFile" do
  let(:dir_num) do
    @dir_num ||= rand(100000000000)
  end
  let(:tmp_dir) do
    "/Users/mharris717/tmp2/nested"
  end
  let(:parent_dir) { "#{tmp_dir}/test_parent#{dir_num}" }
  let(:child_dir) { "#{tmp_dir}/test#{dir_num}" }

  def fork_mount
    ec "mkdir #{parent_dir}", silent: true
    ec "mkdir #{child_dir}", silent: true
    File.create "#{parent_dir}/zzz.txt","hello"

    pid = fork do
      cmd = "bundle exec ruby ./bin/nested_file #{parent_dir} #{child_dir}"
      exec cmd
    end

    sleep 0.05
    try_for_period(2) do
      File.read("#{child_dir}/zzz.txt")
    end

    d = File.basename(child_dir)
    mount_name = ec("mount", silent: true).split("\n").select { |x| x =~ /#{d}/ }.first.split(" ").first
    {pid: pid, mount_name: mount_name}
  end

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

  before(:all) do
    @fork_data = fork_mount
  end
  after(:all) do
    if @fork_data
      Process.kill "KILL",@fork_data[:pid] 
      ec "umount #{@fork_data[:mount_name]}", silent: true
    end
  end

  before(:each) do
    # FileUtils.mkdir(parent_dir) unless FileTest.exist?(parent_dir)
    `rm -rf #{parent_dir}/*`
    Dir["spec/parent_template/*"].each do |f|
      `cp -r #{f} #{parent_dir}`
    end

    Dir["#{parent_dir}/**/*.txt"].each do |file|
      body = File.read(file).gsub("{{NF_ROOT}}",NestedFile.root).gsub("{{NF_PARENT_DIR}}",parent_dir)
      File.create file, body
    end

    # sleep 1
  end

  describe "basic reads" do
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

    it 'ls should work in subs' do
      #create_child_file
      ec("ls #{child_dir}/sub2").strip.should == "x.txt"
      # raise Dir["#{child_dir}/*"].inspect
    end
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

  
  describe 'saving file with sections writes to other files' do
    before(:each) do
      #puts "Before:\n" + Dir["#{child_dir}/*.txt"].join("\n")
      body = "<file c.txt>\nI was here\n</file>"
      create_child_file "b.txt",body
      #puts "After:\n" + Dir["#{child_dir}/*.txt"].join("\n")

      # Dir["#{child_dir}/*.txt"].each do |f|
      #   c = File.read(f).length
      #   puts "#{f}: #{c} #{FileTest.exist?(f)}"
      # end

    end

    it 'exists' do
      FileTest.should be_exist("#{parent_dir}/b.txt")
      FileTest.should be_exist("#{child_dir}/b.txt")
      FileTest.should be_exist("#{parent_dir}/c.txt")
      FileTest.should be_exist("#{child_dir}/c.txt")
    end

    it 'c.txt has written text' do
      File.read("#{parent_dir}/c.txt").should == "I was here"
    end

  end

  if true
  
  describe 'saving file with sections writes to other files - relative path' do
    before(:each) do
      body = "<file c.txt>\nI was here\n</file>"
      create_child_file "b.txt", body
    end

    it 'exists' do
      FileTest.should be_exist("#{parent_dir}/b.txt")
      FileTest.should be_exist("#{child_dir}/b.txt")
      FileTest.should be_exist("#{parent_dir}/c.txt")
      FileTest.should be_exist("#{child_dir}/c.txt")
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

  describe 'modifying file referenced elsewhere updates other file' do
    it 'writing to parent - longer string - include_others.txt has written text' do
      create_parent_file "a.txt", "Hello There"
      sleep 1

      body = "<file #{parent_dir}/a.txt>\nHello There\n</file>"
      File.read("#{parent_dir}/include_others.txt").should == "<file #{parent_dir}/a.txt>\n</file>"
      File.read("#{child_dir}/include_others.txt").should == body
    end

    it 'writing to child - longer string - include_others.txt has written text' do
      create_child_file "a.txt", "Hello There"
      sleep 0.3

      body = "<file #{parent_dir}/a.txt>\nHello There\n</file>"
      File.read("#{parent_dir}/include_others.txt").should == "<file #{parent_dir}/a.txt>\n</file>"
      File.read("#{child_dir}/include_others.txt").should == body
    end

    it 'writing to parent - shorter string - include_others.txt has written text' do
      create_parent_file "a.txt", "bb"
      sleep 0.3

      body = "<file #{parent_dir}/a.txt>\nbb\n</file>"
      File.read("#{parent_dir}/include_others.txt").should == "<file #{parent_dir}/a.txt>\n</file>"
      File.read("#{child_dir}/include_others.txt").should == body
    end

    it 'writing to child - shorter string - include_others.txt has written text' do
      # puts "\n\nSPEC START\n\n"
      #sleep 1
      create_child_file "a.txt", "bb"
      # ec "echo '' > #{child_dir}/a.txt"
      # puts "CREATED"
      sleep 0.3

      body = "<file #{parent_dir}/a.txt>\nbb\n</file>"
      File.read("#{parent_dir}/include_others.txt").should == "<file #{parent_dir}/a.txt>\n</file>"
      File.read("#{child_dir}/include_others.txt").should == body
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
