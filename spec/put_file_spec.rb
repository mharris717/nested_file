require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

class FakeConvert
  def mount_to_parent(path)
    path
  end
  def parent_to_mount(path)
    path
  end
  def mount_to_parent_if_relative(path)
    path
  end
end

describe "PutFile" do
  def new_file(body)
    NestedFile::PutFile.new(convert_path: FakeConvert.new, raw_body: body)
  end
  it 'smoke' do
    body = "<file a.txt>\n</file>"
    file = NestedFile::PutFile.new(convert_path: FakeConvert.new, raw_body: body)
    file.parsed_body.should == "<file a.txt>\n\n</file>"
  end

  it 'single tag' do
    body = "<file a.txt/>"
    file = NestedFile::PutFile.new(convert_path: FakeConvert.new, raw_body: body)
    file.parsed_body.should == "<file a.txt>\n\n</file>"
  end

  describe "reads included file" do
    include_context "file stub"

    it "reads" do
      body = "<file a.txt />\nMore Stuff"
      file_stub.add "a.txt","hello"
      new_file(body).parsed_body.should == "<file a.txt>\nhello\n</file>\nMore Stuff"
    end

    it "reads partial" do
      body = "<file a.txt:3..4 />\nMore Stuff"
      file_stub.add "a.txt","a\n\nb\nc\nd"
      new_file(body).parsed_body.should == "<file a.txt:3..4>\nb\nc\n</file>\nMore Stuff"
    end
  end

end