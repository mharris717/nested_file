require 'rubygems'
require 'rfusefs'
require 'mharris_ext'


module NestedFile
  def self.tmp_dir
    res = File.expand_path(File.dirname(__FILE__))+"/../tmp"
    File.expand_path(res)
  end
end

class File
  class << self
    def create(filename,str)
      open(filename,"w") do |f|
        f << str
      end
    end
    def append(filename,str)
      open(filename,"a") do |f|
        f << str
      end
    end
    def pp(filename,obj)
      require 'pp'
      open(filename,"w") do |f|
        PP.pp obj,f
      end
    end
  end
end

def log(str)
  #return yield if block_given?
  #return nil
  res = nil
  if block_given?
    res = yield
    str = "#{str} res: #{res}"
  end
  puts str
  File.append "/code/orig/nested_file/debug.log","#{str}\n"
  res
end

File.create "/code/orig/nested_file/debug.log","Starting at #{Time.now}\n"


module NestedFile
  class PutFile
    include FromHash
    attr_accessor :id, :name, :parent_id, :content_type, :put_dir
    attr_accessor :raw_body, :filename

    fattr(:parsed_body) do
      res = raw_body.gsub(/<file (.+?)>(.*?)<\/file>/m) do 
        FileSection.new(:parent_file => self, :file_to_insert => $1).to_s
      end
      res.gsub(/<files (.+?)>(.*?)<\/files>/m) do 
        FileGroup.new(:parent_file => self, :file_glob => $1).to_s
      end
    end

    def write_subs!
      raw_body.scan(/<file (.+?)>(.*?)<\/file>/m) do |m|
        #log "would write #{m[1]} to #{m[0]}"
        #File.create m[0],m[1]

        FileSection.new(:parent_file => self, :file_to_insert => m[0], :parent_body => m[1]).write!
      end
    end
    def write_self!
      res = raw_body.gsub(/<file (.+?)>(.*?)<\/file>/m) do
        "<file #{$1}>\n</file>"
      end
      File.create filename, res
    end
    def write_all!
      write_subs!
      write_self!
    end
  end

  class FileSection
    include FromHash
    attr_accessor :parent_file, :file_to_insert, :parent_body
    fattr(:full_file_to_insert) do
      File.expand_path(file_to_insert,File.dirname(parent_file.filename))
    end
    fattr(:insert_body) do
      if FileTest.exist?(full_file_to_insert)
        File.read(full_file_to_insert)
      else
        log "file to insert #{full_file_to_insert} into #{parent_file.filename} doesn't exist"
        ""
      end
    end
    fattr(:trimmed_parent_body) do
      res = parent_body
      res = res[1..-1] if res[0..0] == "\n"
      res = res[0..-2] if res[-1..-1] == "\n"
      res
    end
    def to_s
      "<file #{file_to_insert}>\n#{insert_body}\n</file>"
    end
    def should_write?
      trimmed_parent_body.present?
    end
    def write!
      return unless should_write?
      log "writing to #{full_file_to_insert} from #{parent_file.filename}"
      File.create full_file_to_insert, trimmed_parent_body
    end
  end

  class FileGroup
    include FromHash
    attr_accessor :parent_file, :file_glob
    fattr(:full_glob) do
      File.expand_path(file_glob,File.dirname(parent_file.filename))
    end
    fattr(:files_to_insert) do
      log "expanded #{file_glob} -> #{full_glob} ->" do
        Dir[full_glob].sort
      end
    end
    fattr(:sections) do
      files_to_insert.map do |f|
        FileSection.new(:parent_file => parent_file, :file_to_insert => parent_file.put_dir.parent_to_mount(f))
      end
    end
    def to_s
      res = sections.join("\n")
      "<files #{file_glob}>\n#{res}\n</files>"
    end
  end

  class PutDir
    include FromHash
    attr_accessor :parent_dir, :mount_dir
    def mount_to_parent(path)
      #path.gsub(mount_dir,parent_dir)
      #log "mount to parent converted #{path} to" do
        fixed_path = (path == '/') ? "" : path
        "#{parent_dir}#{fixed_path}"
      #end
    end
    def parent_to_mount(path)
      #log "parent_to_mount #{path} to" do
        path.gsub("#{parent_dir}/","")
      #end
    end
    def contents(path)
      log "contents for #{path}" do
        parent_path = mount_to_parent(path)
        Dir["#{parent_path}/*"].map { |x| parent_to_mount(x) }
      end
    end
    def file?(path)
      exist = FileTest.exist?(mount_to_parent(path))
      log "file? #{path} exist #{exist}" do
        FileTest.file? mount_to_parent(path)
      end
    end
    def directory?(path)
      exist = FileTest.exist?(mount_to_parent(path))
      log "directory? #{path} exist #{exist}" do
        FileTest.directory? mount_to_parent(path)
      end
    end
    def read_file(path)
      log "read file #{path}" do
        body = File.read(mount_to_parent(path))
        PutFile.new(:raw_body => body, :filename => mount_to_parent(path), :put_dir => self).parsed_body
      end
    end
    def size(path)
      log "size for #{path}" do
        read_file(path).size
      end
    end


    def can_write?(path)
      true
    end

    def write_to(path,contents)
      file = PutFile.new(:raw_body => contents, :filename => mount_to_parent(path))
      file.write_all!
      #f = mount_to_parent(path)
      #log "writing to #{f}"
      #File.create f, contents
    end
  end
end