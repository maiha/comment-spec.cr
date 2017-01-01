require "./spec_helper"

describe CommentSpec do
  it "Usage" do
    CommentSpec.parse("1 + 2 # => 3").should eq("( 1 + 2 ).should eq( 3 )")
  end
end
