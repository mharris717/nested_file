require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "PutDir" do
  include_context "file stub"

  it 'smoke' do
    file_stub.add "/a/b/c/a.txt","hello"
    dir = NestedFile::PutDir.new(parent_dir: "/a/b", mount_dir: "/z")
    dir.contents("/").should == ['c']
    dir.contents("/c").should == ['a.txt']
    dir.read_file("/c/a.txt").should == 'hello'
  end

  it "nested read" do
    file_stub.add "/a/b/a.txt","Hello"
    file_stub.add "/a/b/b.txt","<file a.txt>\n</file>"

    dir = NestedFile::PutDir.new(parent_dir: "/a/b", mount_dir: "/z")
    dir.read_file("b.txt").should == "<file a.txt>\nHello\n</file>"
  end

  it "different relative dir" do
    file_stub.add "/a/b/a.txt","Hello"
    file_stub.add "/a/b/b.txt","<file a.txt>\n</file>"
    file_stub.add "/c/d/a.txt","Goodbye"

    dir = NestedFile::PutDir.new(parent_dir: "/a/b", mount_dir: "/z", relative_dir: "/c/d")
    dir.read_file("b.txt").should == "<file a.txt>\nGoodbye\n</file>"
  end

  it "different relative dir - file group" do
    file_stub.add "/a/b/a.txt","Junk"
    file_stub.add "/a/b/multiple.txt","<files *.txt>\n</files>"
    file_stub.add "/c/d/c.txt","Hello"
    file_stub.add "/c/d/d.txt","Goodbye"

    exp = <<EOF
<files *.txt>
<file c.txt>
Hello
</file>
<file d.txt>
Goodbye
</file>
</files>
EOF

    dir = NestedFile::PutDir.new(parent_dir: "/a/b", mount_dir: "/z", relative_dir: "/c/d")
    dir.read_file("multiple.txt").should == exp.strip
  end

  it "write subs - relative" do
    
    # File.any_instance_of.stub(:write) do
    #   raise "file.write call"
    # end

    # raw_write(path,offset,sz,buf,file=nil)
    dir = NestedFile::PutDir.new(parent_dir: "/a/b", mount_dir: "/z", relative_dir: "/c/d")
    dir.raw_write "a.txt",0,nil,"<file b.txt>\nHello</file>"
    Dir.entries("/a/b").should == ['a.txt']
  end



end