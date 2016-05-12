require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

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
end

describe "FileSection" do
  let(:file_stub) do
    FileStub.new
  end

  before(:each) do
    FileTest.stub(:exist?) { |file| file_stub.exist?(file) }
    File.stub(:read) { |file| file_stub.read(file) }
  end

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
end