module NestedFile
  module FileSection
    def self.new(*args)
      Read.new(*args)
    end

    class Read
      include FromHash
      attr_accessor :file_to_insert, :full_file_to_insert

      fattr(:insert_body) do
        if FileTest.exist?(full_file_to_insert)
          res = File.read(full_file_to_insert)
          if $use_indent
            res = res.split("\n").map { |x| "  #{x}" }.join("\n")
          end
          res
        else
          log "file to insert #{full_file_to_insert} doesn't exist"
          ""
        end
      end

      def to_s
        "<#{ftag} #{file_to_insert}>\n" + insert_body + "\n</#{ftag}>"
      end
    end

    class Write
      include FromHash
      attr_accessor :parent_body, :full_file_to_insert

      fattr(:trimmed_parent_body) do
        raise "no parent_body for #{full_file_to_insert}" unless parent_body
        res = parent_body.scan(/\A\n?(.*?)\n?\Z/m).first.first

        lines = res.split("\n")
        min_indent = 99999
        lines.each do |line|
          if line.present?
            raise 'bad' unless line =~ /^(\s*)/
            min_indent = [min_indent,$1.length].min
          end
        end

        if min_indent > 0 && min_indent < 1000
          lines = lines.map { |x| x[min_indent..-1] }
          res = lines.join("\n")
        end

        res
      end

      def should_write_inner
        return false
        return false unless trimmed_parent_body.present?
        if FileTest.exist?(full_file_to_insert)
          return false if trimmed_parent_body == File.read(full_file_to_insert)
        end
        true
      end
      fattr(:should_write) { should_write_inner }
      def should_write?; should_write; end
      def write!
        return unless should_write?
        log "writing to #{full_file_to_insert}"
        File.create full_file_to_insert, trimmed_parent_body
      end
    end
  end
end

module NestedFile
  module FileSection
    class Partial
      include FromHash
      attr_accessor :file_to_insert, :full_file_to_insert, :lines, :parent_body

      def sub_lines(str)
        ls = str.split("\n")
        r = (lines.begin-1)..(lines.end-1)
        ls[r].join("\n")
      end

      fattr(:insert_body) do
        if FileTest.exist?(full_file_to_insert)
          res = File.read(full_file_to_insert)
          res = sub_lines(res)
          if $use_indent
            res = res.split("\n").map { |x| "  #{x}" }.join("\n")
          end
          res
        else
          log "file to insert #{full_file_to_insert} doesn't exist"
          ""
        end
      end

      def to_s
        "<#{ftag} #{file_to_insert}>\n" + insert_body + "\n</#{ftag}>"
      end
    end
  end
end