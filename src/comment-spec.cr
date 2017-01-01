require "./comment-spec/**"

class CommentSpec
  getter builder
  
  def initialize(@line : String)
    @builder = Builder.from_line(@line)
  end

  def spec
    @builder.build
  end
end
