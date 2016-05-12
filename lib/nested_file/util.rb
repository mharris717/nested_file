module NestedFile
  def self.root
    res = File.expand_path(File.dirname(__FILE__))+"/../.."
    File.expand_path(res)
  end
  def self.tmp_dir
    File.join root, "tmp"
  end
end

class File
  class << self
    def create(filename,str)
      # puts "File.create #{filename}"
      open(filename,"w") do |f|
        f << str
        # f.flush
      end
    end
    def append(filename,str)
      open(filename,"a") do |f|
        f << str
        f.flush
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
  # puts str
  File.append "/code/orig/nested_file/debug.log","#{str}\n"
  res
end

File.create "/code/orig/nested_file/debug.log","Starting at #{Time.now}\n"