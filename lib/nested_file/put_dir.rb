module NestedFile
  class ConvertPath
    include FromHash
    attr_accessor :parent_dir, :mount_dir, :actual_parent_dir
    # converts the directory relative to the mount point to an absolute parent path
    def mount_to_parent(path)
      if path.include?('PARENT_ROOT')
        path.gsub('PARENT_ROOT',actual_parent_dir)
      else
        File.join parent_dir, path
      end
    end
    def parent_to_mount(path)
      path.gsub("#{parent_dir}/","")
    end
    def mount_to_parent_if_relative(path)
      if Pathname.new(path).absolute?
        path
      else
        mount_to_parent(path)
      end
    end
  end

  class PutDir
    include FromHash
    attr_accessor :parent_dir, :mount_dir, :relative_dir
    
    fattr(:convert_path) do
      ConvertPath.new(parent_dir: parent_dir, mount_dir: mount_dir, actual_parent_dir: parent_dir)
    end
    fattr(:relative_convert_path) do
      ConvertPath.new(parent_dir: relative_dir||parent_dir, mount_dir: mount_dir, actual_parent_dir: parent_dir)
    end
    extend Forwardable
    def_delegators :convert_path, :mount_to_parent, :parent_to_mount

    def contents(path)
      log "contents for #{path}" do
        parent_path = mount_to_parent(path)
        res = Dir.entries(parent_path)
        res.map { |x| File.basename(x) }
      end
    end
    def file?(path)
      FileTest.file? mount_to_parent(path)
    end
    def directory?(path)
      FileTest.directory? mount_to_parent(path)
    end
    def read_file_inner(path)
      body = File.read(mount_to_parent(path))
      PutFile.new(raw_body: body, filename: mount_to_parent(path), convert_path: relative_convert_path).parsed_body
    end
    def read_file(path)
      log "read file #{path}" do
        read_file_inner path
      end
    end
    def size(path)
      log "size for #{path}" do
        read_file_inner(path).size
      end
    end

    module Raw
      def raw_open(path,*args)
        if args[0] == 'w'
          File.new(mount_to_parent(path),'w')
        else
          nil
        end
      end
      def raw_truncate(path,i,f)
        f.truncate(i)
      end
      def raw_close(*args)
        args.last.close
      end
      def raw_write(path,offset,sz,buf,file=nil)
        PutFile.new(raw_body: buf, filename: mount_to_parent(path), convert_path: relative_convert_path).write_all! file
        buf.length
      end
    end
    include Raw

    def can_write?(path)
      true
    end
  end
end