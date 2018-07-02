class CommentSpec
  def self.parse(line, fallback = true)
    parser = LexerParser.parse(line)
  rescue err
    raise err if !fallback
    RegexParser.parse(line)
  end
end
