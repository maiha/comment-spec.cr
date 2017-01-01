require "./comment-spec/**"

class CommentSpec
  def initialize(@line : String)
    @builder = Builder.from_line(line)
  end

  def spec
    @builder.build
  end
end
