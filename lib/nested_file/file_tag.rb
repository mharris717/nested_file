require 'mharris_ext'

module FileTag
  class Definition
    include FromHash
    attr_accessor :reg, :names
  end
  class DSL
    include FromHash
    fattr(:definitions) { [] }
    def tag(reg,*names)
      self.definitions << Definition.new(:reg => reg, :names => names)
    end
  end

  def self.configure(&b)
    dsl = DSL.new
    b[dsl]
    puts "Defs #{dsl.definitions.size}"
  end
end

FileTag.configure do |t|
  t.tag /app\/models\/(.+)\.rb/, :model, 1
end