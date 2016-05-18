require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "FileSection" do
  include_context "file stub"
  
  it 'smoke' do
    file = "/a/b/c"
    body = 'abc'
    file_stub.add file,body
    section = NestedFile::FileSection.new(full_file_to_insert: file, file_to_insert: file)
    section.insert_body.should == body
    section.to_s.should == "<file /a/b/c>\nabc\n</file>"
  end

  it 'smoke' do
    file = "c.txt"
    file_stub.add "/a/c.txt",'abc'

    section = NestedFile::FileSection.new(file_to_insert: file, full_file_to_insert: "/a/c.txt")
    section.to_s.should == "<file c.txt>\nabc\n</file>"
  end

  it "reading file that doesn't exist" do
    section = NestedFile::FileSection.new(full_file_to_insert: "a.txt", file_to_insert: nil)
    section.insert_body.should == ''
  end

  it 'trimmed_body only trims 1 newline' do
    section = NestedFile::FileSection::Write.new(parent_body: "\n\nabc\n")
    section.trimmed_parent_body.should == "\nabc"
  end

  it 'respects global indent' do
    section = NestedFile::FileSection::Write.new(parent_body: "  a\n   b\n\n  c")
    section.trimmed_parent_body.should == "a\n b\n\nc"
  end
end