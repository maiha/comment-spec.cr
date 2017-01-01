require "./comment-spec/**"

class CommentSpec
  def self.parse(line)
    Builder.from_line(line).build
  end
end
