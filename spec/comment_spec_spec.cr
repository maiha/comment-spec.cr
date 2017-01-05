require "./spec_helper"

private macro parse(line, spec)
  CommentSpec.parse({{line}}).should eq({{spec}})
end

private macro equal(line, str)
  CommentSpec.parse({{line}}).should eq("( value ).should eq( " + {{str}} + " )")
end

private macro equal_string(line, str)
  CommentSpec.parse({{line}}).should eq("( value ).to_s.should eq( \"" + {{str}}+ "\" )")
end

private macro nop(line)
  CommentSpec.parse({{line}}).should eq({{line}})
end

private macro comment_out(line)
  CommentSpec.parse({{line}}).should eq("# " + {{line}})
end

describe "CommentSpec" do
  describe ".parse" do
    it "require" do
      comment_out "require \"json\""
    end

    it "dynamic values" do
      nop "a.object_id # => 1"
      nop "file.mtime # => 2015-10-20 13:11:12 UTC"
      nop "foo.hash # => 1234"
      nop "a.sample(2) # => [2, 1]"
      nop "time.to_utc # => xxx"
      nop "time.to_local # => xxx"
      nop "time.local_offset_in_minutes # => xxx"
    end

    it "raises" do
      parse "v[10] # raises IndexError", "expect_raises(IndexError) { v[10] }"
      parse "value # raises IO::Timeout (after 1 second)", "expect_raises(IO::Timeout) { value }"
    end

    it "type" do
      parse "value # => #<XXX>", "( value ).class.to_s.should eq( \"XXX\" )"
      parse "value # => #<Regex::MatchData y>", "( value ).class.to_s.should eq( \"Regex::MatchData\" )"
      parse "value # => #<URI:0x1068a7e40 @port=nil>", "( value ).class.to_s.should eq( \"URI\" )"
    end

    it "Time::Span" do
      parse "value # => 01:00:00", "( value ).should eq( Time::Span.new(0, 1, 0, 0, 0) )"
      parse "value # => 01.02:03:04", "( value ).should eq( Time::Span.new(1, 2, 3, 4, 0) )"
      parse "value # => 00:00:00.010", "( value ).should eq( Time::Span.new(0, 0, 0, 0, 10) )"
    end  

    it "Time" do
      parse "value # => 2016-04-05 12:36:21", "( value ).should eq( Time.parse(\"2016-04-05 12:36:21\", \"%F %T\") )"
      parse "value # => 2016-04-05 12:36:21 UTC", "( value ).should eq( Time.parse(\"2016-04-05 12:36:21 UTC\", \"%F %T %z\") )"
      parse "value # => 2016-04-05 12:36:21.023 UTC", "( value ).should eq( Time.parse(\"2016-04-05 12:36:21.023 UTC\", \"%F %T.%L %z\") )"
    end

    it "`=>` found but nop" do
      nop "value # => [9, #<Indexable::ItemIterator>]"
      nop "# => 1"
    end

    it "comment" do
      nop "a # foo"
    end

    it "empty" do
      equal_string "value # => []"  , "[]"
      equal_string "value # => [[]]", "[[]]"
      equal_string "value # => {}  ", "{}"
    end

    it "BigInt" do
      # \d{20,} (BigInt)
      equal_string "value # => 12345678912345678912345", "12345678912345678912345"
    end

    it "Rational" do
      equal_string "value # => 1/6", "1/6"
    end

    it "Float" do
      parse "value # => 1234.6", "( value ).try(&.to_f).to_s.should eq( \"1234.6\" )"
      parse "value.to_f? # => 1234.6", "( value.to_f? ).to_s.should eq( \"1234.6\" )"
    end

    it "String" do
      equal_string "value # => \"BitArray[000000000000]\"", "BitArray[000000000000]"
    end

    it "Complex Literal" do
      equal_string "value # => 1.0 + 0.0i", "1.0 + 0.0i"
    end

    it "CSV::Token" do
      equal_string "value # => CSV::Token(@kind=Cell, @value=\"one\")", "CSV::Token(@kind=Cell, @value=\\\"one\\\")"
    end  

    it "Compilation Errors" do
      comment_out "[] # syntax error"
    end

    it "remove trailing string as comment" do
      equal "value # => 1 (Bob's index)", "1"
    end

    it "partial code" do
      nop "struct Foo # < Struct"
    end
  end
end
