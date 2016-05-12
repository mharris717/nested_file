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
        res = Dir["#{parent_path}/*"]
        # puts res.inspect
        res = res.map { |x| parent_to_mount(x) }
        if path != "/"
          res = res.map do |f|
            r = /^#{path[1..-1]}\//
            raise "no match" unless f =~ r
            f2 = f.gsub(r,"")
            log "subbed #{f} into #{f2}"
            f2
          end
        end
        res
      end
    end
    def file?(path)
      exist = FileTest.exist?(mount_to_parent(path))
      #log "file? #{path} exist #{exist}" do
        FileTest.file? mount_to_parent(path)
      #end
    end
    def directory?(path)
      exist = FileTest.exist?(mount_to_parent(path))
      #log "directory? #{path} exist #{exist}" do
        FileTest.directory? mount_to_parent(path)
      #end
    end
    def read_file_inner(path)
      body = File.read(mount_to_parent(path))
      PutFile.new(raw_body: body, filename: mount_to_parent(path), put_dir: self).parsed_body
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

    class FakeFile
      include FromHash
      attr_accessor :filename, :wrote
      fattr(:file) do
        File.new(filename,"w")
      end

      def close
        file.close
      end

      def write(str)
        PutFile.new(raw_body: str, filename: filename).write_all! file
        str.length
      end

      def truncate(i)
        file.truncate(i)
      end
    end

    def raw_open(path,*args)
      log "raw_open #{path} #{args.inspect}" 
      if args[0] == 'w'
        FakeFile.new(filename: mount_to_parent(path))
      else
        nil
      end
    end
    def raw_truncate(path,i,f)
      log "raw_truncate #{path} #{i} #{f}"
      f.truncate(i)
    end
    def raw_close(*args)
      log "raw_close #{args.inspect}"
      args.last.close
    end
    def raw_write(path,offset,sz,buf,file=nil)
      log "raw_write #{path} #{offset} #{sz} #{buf} #{file}"
      file.write buf
    end

    def can_write?(path)
      #log("can_write? path") do
        true
      #end
    end

    def write_to(path,contents)
      raise 'write_to'
      20.times { log "write_to #{path} #{contents}" }
      file = PutFile.new(:raw_body => contents, :filename => mount_to_parent(path))
      file.write_all!
      #f = mount_to_parent(path)
      #log "writing to #{f}"
      #File.create f, contents
    end

    # def xattr(*args)
    #   {}
    # end
    # def statistics(*args)
    #   {}
    # end
  end
end