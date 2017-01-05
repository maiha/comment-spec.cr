require "./spec_helper"

private def parse(line, code, doc)
  parser = CommentSpec::Lexer.new(line)
  {parser.code, parser.doc?}.should eq({code, doc})
end

private macro spec(line, spec)
  CommentSpec::LexerParser.parse({{line}}).should eq({{spec}})
end

describe "Lexer" do
  it "#parse" do
    parse "[1,2,3]"      , "[1,2,3]", nil
    parse "value # => 1" , "value"  , "=> 1"
  end
end

describe "LexerParser" do
  it "#spec" do
    spec "v # => {}  ", "( v ).to_s.should eq( \"{}\" )"
    spec "[1,2,3]"      , "[1,2,3]"
    spec "value # => 1" , "( value ).should eq( 1 )"

    spec "1 + 2 # => 3" , "( 1 + 2 ).should eq( 3 )"
    spec "value # => 2016-03-31 12:36:21", "( value ).should eq( Time.parse(\"2016-03-31 12:36:21\", \"%F %T\") )"
    spec "v[10] # raises IndexError", "expect_raises(IndexError) { v[10] }"
    spec "value # => #<XXX>", "( value ).class.to_s.should eq( \"XXX\" )"
    spec "# => 1", "# => 1"
    spec "a # foo", "a # foo"
#    spec "struct Foo # < Struct", "struct Foo # < Struct"
  end
end
