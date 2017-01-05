require "./spec_helper"

describe "Usage in README.md" do
  it "Usage" do
    CommentSpec.parse("1 + 2 # => 3").should eq("( 1 + 2 ).should eq( 3 )")
    CommentSpec.parse("value # => 2016-03-31 12:36:21").should eq("( value ).should eq( Time.parse(\"2016-03-31 12:36:21\", \"%F %T\") )")
    CommentSpec.parse("v[10] # raises IndexError").should eq("expect_raises(IndexError) { v[10] }")
    CommentSpec.parse("value # => #<XXX>").should eq("( value ).class.to_s.should eq( \"XXX\" )")
  end
end
