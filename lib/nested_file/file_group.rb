module NestedFile
  class FileGroup
    include FromHash
    attr_accessor :parent_file, :file_glob, :convert_path, :full_glob
    fattr(:files_to_insert) do
      log "expanded #{file_glob} -> #{full_glob} ->" do
        Dir[full_glob].sort
      end
    end
    fattr(:sections) do
      files_to_insert.map do |f|
        fp = convert_path.parent_to_mount(f)
        FileSection.new(file_to_insert: fp, full_file_to_insert: f)
      end
    end
    def to_s
      res = sections.join("\n")
      "<#{ftag}s #{file_glob}>\n#{res}\n</#{ftag}s>"
    end
  end
end