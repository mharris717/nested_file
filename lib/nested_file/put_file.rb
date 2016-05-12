module NestedFile
  class PutFile
    include FromHash
    attr_accessor :id, :name, :parent_id, :content_type, :put_dir
    attr_accessor :raw_body, :filename

    fattr(:parsed_body) do
      res = raw_body.gsub(/<file (.+?)>.*?<\/file>/m) do 
        FileSection.new(parent_file: self, file_to_insert: $1).to_s
      end
      res.gsub(/<files (.+?)>.*?<\/files>/m) do 
        FileGroup.new(parent_file: self, file_glob: $1).to_s
      end
    end

    def write_subs!
      raw_body.scan(/<file (.+?)>(.*?)<\/file>/m) do |m|
        FileSection::Write.new(parent_file: self, file_to_insert: m[0], parent_body: m[1]).write!
      end
    end
    def write_self!(file=nil)
      res = raw_body.gsub(/<file (.+?)>(.*?)<\/file>/m) do
        "<file #{$1}>\n</file>"
      end
      # puts "write_self! #{filename} #{res}"

      if file
        # puts "IN WRITE PART"
        file.write res
      else
        File.create filename, res
      end
    end
    def write_all!(file=nil)
      write_subs!
      write_self!(file)
    end
  end
end