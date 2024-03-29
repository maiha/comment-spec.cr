class CommentSpec
  module Builder
    abstract def build : String

    def name
      self.class.name.split(/::/).last
    end
  end

  abstract class BaseBuilder(T)
    include Builder
    getter line
    getter! data

    def initialize(@line : String, @data : T = nil)
    end
  end

  class CommentOut < BaseBuilder(Nil)
    def build : String
      "# #{line}"
    end
  end

  class Nop < BaseBuilder(Nil)
    def build : String
      line
    end
  end

  class ExpectRaises < BaseBuilder(NamedTuple(code: String, err: String))
    def build : String
      "expect_raises(%s) { %s }" % [data["err"], data["code"]]
    end
  end

  class ExpectClass < BaseBuilder(NamedTuple(code: String, eq: String))
    def build : String
      "( %s ).class.to_s.should eq( \"%s\" )" % [data["code"], data["eq"]]
    end
  end

  class ExpectEqual < BaseBuilder(NamedTuple(code: String, eq: String))
    def build : String
      "( %s ).should eq( %s )" % [data["code"], data["eq"]]
    end
  end

  class ExpectStringEqual < BaseBuilder(NamedTuple(code: String, eq: String))
    def build : String
      "( %s ).to_s.should eq( \"%s\" )" % [data["code"], data["eq"]]
    end
  end

  class ExpectTryFloat < BaseBuilder(NamedTuple(code: String, eq: String))
    def build : String
      "( %s ).try(&.to_f).to_s.should eq( \"%s\" )" % [data["code"], data["eq"]]
    end
  end
end
