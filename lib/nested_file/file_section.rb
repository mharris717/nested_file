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
          File.read(full_file_to_insert)
        else
          log "file to insert #{full_file_to_insert} doesn't exist"
          ""
        end
      end

      def to_s
        "<file #{file_to_insert}>\n#{insert_body}\n</file>"
      end
    end

    class Write
      include FromHash
      attr_accessor :parent_body, :full_file_to_insert

      fattr(:trimmed_parent_body) do
        parent_body.scan(/\A\n?(.*?)\n?\Z/m).first.first
      end

      def should_write?
        trimmed_parent_body.present?
      end
      def write!
        return unless should_write?
        log "writing to #{full_file_to_insert}"
        File.create full_file_to_insert, trimmed_parent_body
      end
    end
  end
end