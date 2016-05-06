module NestedFile
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
      puts "FileSection write!"
      return unless should_write?
      log "writing to #{full_file_to_insert} from #{parent_file.filename}"
      # File.create full_file_to_insert, trimmed_parent_body

      File.open(full_file_to_insert,"w") do |f|
        f << trimmed_parent_body
        f.flush
      end
    end
  end
end