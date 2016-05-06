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
        # puts caller.join("\n")
        read_file_inner(path).size
      end
    end

    def delete(*args)
      raise 'delete'
    end

    class FakeFile
      include FromHash
      attr_accessor :filename, :wrote
      fattr(:file) do
        File.new(filename,"w")
      end

      def close
        file.close
        # self.wrote = nil
        
      end

      def write(str)
        puts "str class #{str.class}"
        self.wrote = str
        PutFile.new(raw_body: str, filename: filename).write_all! file
        str.length
      end

      def truncate(i)
        file.truncate(i)
      end
    end

    def raw_open(path,*args)

      puts "raw_open #{path} #{args.inspect}" 
      # return nil
      if args[0] == 'w'
        FakeFile.new(filename: mount_to_parent(path))
        # path
      else
        nil
      end
    end
    def raw_truncate(path,i,f)
      # return nil
      puts "raw_truncate #{path} #{i} #{f}"
      f.truncate(i)
      #f.close
    end
    def raw_close(*args)
      # return nil
      puts "raw_close #{args.inspect}"
      args.last.close


    end
    def raw_write(path,offset,sz,buf,file=nil)
      # return nil
        puts "raw_write #{path} #{offset} #{sz} #{buf} #{file}"
        #pfile = PutFile.new(:raw_body => buf, :filename => mount_to_parent(path))
        #pfile.write_all! file
        file.write buf
        # File.open(mount_to_parent(path),"w") do |f|
        #   f.write buf
        # end
        
        # file.write_all!
        # # puts "here"
        # File.open(mount_to_parent(path),"w")


    end

    # @!visibility private
    def raw_sxync(path,datasync,file=nil)
        raise "raw_sync"
    end


    def can_write?(path)
      #log("can_write? path") do
        true
      #end
    end

    def write_to(path,contents)
      # puts caller.join("\n")
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