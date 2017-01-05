require "./spec_helper"

private macro spec(line, spec)
  CommentSpec::Parser.parse({{line}}).should eq({{spec}})
end

describe "Parser" do
  it "#spec" do
    spec "[1,2,3]"      , "[1,2,3]"
    spec "value # => 1" , "( value ).should eq( 1 )"

    spec "1 + 2 # => 3" , "( 1 + 2 ).should eq( 3 )"
    spec "value # => 2016-03-31 12:36:21", "( value ).should eq( Time.parse(\"2016-03-31 12:36:21\", \"%F %T\") )"
    spec "v[10] # raises IndexError", "expect_raises(IndexError) { v[10] }"
    spec "value # => #<XXX>", "( value ).class.to_s.should eq( \"XXX\" )"
  end
end
