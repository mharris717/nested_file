module NestedFile
  class PutFile
    include FromHash
    attr_accessor :raw_body, :filename, :convert_path

    def file_block_regex(tag)
      separate_closing_tag = ">(.*?)<\/#{tag}>"
      /<#{tag}\s+
       (.+?)\s*
       (?:#{separate_closing_tag}|\/>)/mx
    end

    fattr(:parsed_body) do
      res = raw_body.gsub(file_block_regex(:file)) do
        f = $1
        full = convert_path.mount_to_parent_if_relative(f)
        FileSection::Read.new(file_to_insert: f, full_file_to_insert: full).to_s
      end

      res.gsub(file_block_regex(:files)) do 
        f = $1
        full = convert_path.mount_to_parent_if_relative(f)
        FileGroup.new(file_glob: f, full_glob: full, convert_path: convert_path).to_s
      end
    end

    def write_subs!
      raw_body.scan(file_block_regex(:file)) do |m|
        sub_file, sub_body = *m
        #ff = File.expand_path(sub_file,File.dirname(filename))
        full = convert_path.mount_to_parent_if_relative(sub_file)
        FileSection::Write.new(parent_body: sub_body || '', full_file_to_insert: full).write!
      end
    end
    def write_self!(file=nil)
      res = raw_body.gsub(file_block_regex(:file)) do
        "<file #{$1}>\n</file>"
      end
 
      if file
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