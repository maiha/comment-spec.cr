require "./spec_helper"

private def gen(line)
  CommentSpec.new(line).spec
end

describe "Usage in README.md" do
  it "Usage" do
    CommentSpec.parse("1 + 2 # => 3").should eq("( 1 + 2 ).should eq( 3 )")
    CommentSpec.parse("value # => 2016-03-31 12:36:21").should eq("( value ).should eq( Time.parse(\"2016-03-31 12:36:21\", \"%F %T\") )")
    CommentSpec.parse("v[10] # raises IndexError").should eq("expect_raises(IndexError) { v[10] }")
  end
end
