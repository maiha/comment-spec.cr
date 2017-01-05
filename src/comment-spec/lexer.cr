require "compiler/crystal/syntax"

class CommentSpec::Lexer
  getter code : String
  getter? doc : String?

  def initialize(line : String)
    parser = Crystal::Parser.new(line + "\ndef  1;end")
    parser.wants_doc = true
    @doc  = parser.parse.as(Crystal::Expressions).last.as(Crystal::Def).doc
    @code = remove_code(line, @doc.to_s)
  end

  private def remove_code(line, doc)
    case doc.size
    when 0
      line
    when 1..line.size
      line[0...(line.size - doc.size)].sub(/\s*#\s*$/, "")
    else
      raise "BUG: invalid doc size (line: '%s', doc: '%s')" % [line, doc]
    end
  end
end
