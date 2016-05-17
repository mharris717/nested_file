module NestedFile
  def self.root
    res = File.expand_path(File.dirname(__FILE__))+"/../.."
    File.expand_path(res)
  end
end

def log(str)
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

# class String
#   def gsub_safe(reg,str,&b)
#     res = gsub(reg,str,&b)
#     c = caller.join("\n")
#     raise "didn't change, gsub #{self} with #{reg}, replace with #{str}\n#{c}" if res == self
#     res
#   end
# end