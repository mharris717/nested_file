module NestedFile
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
        PutFile.new(raw_body: body, filename: mount_to_parent(path), put_dir: self).parsed_body
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