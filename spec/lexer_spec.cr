require "./spec_helper"

private def parse(line, code, doc)
  parser = CommentSpec::Lexer.new(line)
  {parser.code, parser.doc?}.should eq({code, doc})
end

describe "Lexer" do
  it "#parse" do
    parse "[1,2,3]"      , "[1,2,3]", nil
    parse "value # => 1" , "value"  , "=> 1"
  end
end
