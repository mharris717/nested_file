require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'ostruct'

class FileStub
  def add(file,contents)
    self.files[file] = contents
  end
end

describe "FileSection" do
  it 'smoke' do
    file = "/a/b/c"

    body = 'abc'
    FileTest.stub(:exist?) { true }
    File.stub(:read) { body }

    section = NestedFile::FileSection.new(full_file_to_insert: file, file_to_insert: file)
    section.insert_body.should == "abc"
    section.to_s.should == "<file /a/b/c>\nabc\n</file>"
  end

  it 'smoke' do
    file = "c.txt"
    parent = OpenStruct.new(filename: "/a/b.txt")

    FileTest.stub(:exist?) { true }
    File.stub(:read) do |f|
      if f == '/a/c.txt'
        'abc'
      else
        ''
      end
    end

    section = NestedFile::FileSection.new(file_to_insert: file, parent_file: parent)
    section.to_s.should == "<file c.txt>\nabc\n</file>"
  end
end