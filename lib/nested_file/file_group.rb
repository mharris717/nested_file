module NestedFile
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
end