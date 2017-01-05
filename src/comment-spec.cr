require "./comment-spec/**"

class CommentSpec
  def self.parse(line, fallback = true)
    LexerParser.parse(line)
  rescue err
    raise err if !fallback
    RegexParser.parse(line)
  end
end
