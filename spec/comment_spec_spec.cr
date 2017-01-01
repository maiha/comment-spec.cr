require "./spec_helper"

describe CommentSpec do
  it "Usage" do
    CommentSpec.new("1 + 2 # => 3").should be_a(CommentSpec)
    CommentSpec.new("1 + 2 # => 3").spec.should eq("( 1 + 2 ).should eq( 3 )")
  end
end
