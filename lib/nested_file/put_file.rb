module NestedFile
  class PutFile
    include FromHash
    attr_accessor :raw_body, :filename, :convert_path

    def file_block_regex(tag)
      separate_closing_tag = ">(.*?)<\/#{tag}>"
      /<#{tag}\s+ # opening tag and any whitespace
       (.+?)\s* # file name and any whitespace
       (?:#{separate_closing_tag}|\/>) # either a self closing tag or a body and a closing tag
      /mx
    end

    def split_file_lines(file)
      if file =~ /:/
        file,raw_lines = *file.split(":")
        raise "bad" unless raw_lines =~ /(\d+)\.\.(\d+)/
        lines = ($1.to_i)..($2.to_i)
        [file,lines]
      else
        [file,nil]
      end
    end

    fattr(:parsed_body) do
      res = raw_body.gsub(file_block_regex(:file)) do
        full_f = $1
        f, lines = *split_file_lines(full_f)
        full = convert_path.mount_to_parent_if_relative(f)
        if lines
          FileSection::Partial.new(file_to_insert: full_f, full_file_to_insert: full, lines: lines).to_s
        else
          FileSection::Read.new(file_to_insert: f, full_file_to_insert: full).to_s
        end
      end

      res.gsub(file_block_regex(:files)) do 
        f = $1
        full = convert_path.mount_to_parent_if_relative(f)
        FileGroup.new(file_glob: f, full_glob: full, convert_path: convert_path).to_s
      end
    end

    def write_subs!
      res = []
      raw_body.scan(file_block_regex(:file)) do |m|
        sub_file, sub_body = *m
        full = convert_path.mount_to_parent_if_relative(sub_file)
        res << FileSection::Write.new(parent_body: sub_body || '', full_file_to_insert: full)
      end
      res.each { |x| x.should_write? }
      res.each { |x| x.write! }
    end
    def write_self!(file=nil)
      res = raw_body.gsub(file_block_regex(:file)) do
        "<#{ftag} #{$1}>\n</#{ftag}>"
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