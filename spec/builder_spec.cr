require "./spec_helper"

private macro rule(klass, line, data = nil)
  it {{line}} do
    builder = CommentSpec::Builder.from_line({{line}})
    builder.should be_a(CommentSpec::{{klass}})
    builder.data.should eq({{data}}) if {{data}}
  end
end

describe CommentSpec::Builder do
  # require
  rule CommentOut, "require \"json\""

  # comment
  rule Nop, "# => 1"
  rule Nop, %(# => #<HTTP::Params @raw_params = {"foo" => ["bar", "baz"]>)

  # dynamic values
  rule Nop, "a.object_id # => 1"
  rule Nop, "file.mtime # => 2015-10-20 13:11:12 UTC"
  rule Nop, "foo.hash # => 1234"
  rule Nop, "a.sample(2) # => [2, 1]"
  rule Nop, "time.to_utc # => xxx"
  rule Nop, "time.to_local # => xxx"
  rule Nop, "time.local_offset_in_minutes # => xxx"

  # raises
  rule ExpectRaises, "value # raises IO::Error",
       {code: "value", err: "IO::Error"}
  rule ExpectRaises, "value # raises IO::Timeout (after 1 second)", # ignore trailing comments
       {code: "value", err: "IO::Timeout"}

  # type
  rule ExpectClass, "value # => #<Foo>",
       {code: "value", eq: "Foo"}
  rule ExpectClass, "value # => #<Iterator::Stop>",
       {code: "value", eq: "Iterator::Stop"}
  rule ExpectClass, "value # => #<Regex::MatchData y>",
       {code: "value", eq: "Regex::MatchData"}
  rule ExpectClass, "value # => #<URI:0x1068a7e40 @port=nil>",
       {code: "value", eq: "URI"}

  # Time::Span
  rule ExpectEqual, "value # => 01:00:00",
       {code: "value", eq: "Time::Span.new(0, 1, 0, 0, 0)"}
  rule ExpectEqual, "value # => 01.02:03:04",
       {code: "value", eq: "Time::Span.new(1, 2, 3, 4, 0)"}
  rule ExpectEqual, "value # => 00:00:00.010",
       {code: "value", eq: "Time::Span.new(0, 0, 0, 0, 10)"}
  
  # Time
  rule ExpectEqual, "value # => 2016-04-05 12:36:21",
       {code: "value", eq: %(Time.parse("2016-04-05 12:36:21", "%F %T"))}

  rule ExpectEqual, "value # => 2016-04-05 12:36:21 UTC",
       {code: "value", eq: %(Time.parse("2016-04-05 12:36:21 UTC", "%F %T %z"))}
  rule ExpectEqual, "value # => 2016-04-05 12:36:21.023 UTC",
       {code: "value", eq: %(Time.parse("2016-04-05 12:36:21.023 UTC", "%F %T.%L %z"))}

  # nop when `=>` found but contains comment
  rule Nop, "value # => [9, #<Indexable::ItemIterator>]"
  # nop when `=>` found but contains no codes
  rule Nop, "# => 1"

  # empty array
  rule ExpectStringEqual, "value # => []",
       {code: "value", eq: "[]"}
  # nested empty array
  rule ExpectStringEqual, "value # => [[]]",
       {code: "value", eq: "[[]]"}
  # empty hash
  rule ExpectStringEqual, "value # => {}",
       {code: "value", eq: "{}"}
  # \d{20,} (BigInt)
  rule ExpectStringEqual, "value # => 12345678912345678912345",
       {code: "value", eq: "12345678912345678912345"}
  # rational
  rule ExpectStringEqual, "value # => 1/6",
       {code: "value", eq: "1/6"}

  # Float
  rule ExpectTryFloat, "value # => 1234.6",
       {code: "value", eq: "1234.6"}
  rule ExpectStringEqual, "value.to_f? # => 1234.6",
       {code: "value.to_f?", eq: "1234.6"}
  
  # string
  rule ExpectStringEqual, "value # => \"BitArray[000000000000]\"",
       {code: "value", eq: "BitArray[000000000000]"}

  # Complex format
  rule ExpectStringEqual, "value # => 1.0 + 0.0i",
       {code: "value", eq: "1.0 + 0.0i"}

  # CSV::Token
  rule ExpectStringEqual, "value # => CSV::Token(@kind=Cell, @value=\"one\")",
       {code: "value", eq: "CSV::Token(@kind=Cell, @value=\\\"one\\\")"}
  
  # Compilation Errors
  rule CommentOut, "[] # syntax error"

  # remove trailing string as comment
  rule ExpectEqual, "value # => 1 (Bob's index)",
       {code: "value", eq: "1"}

  # remove puts and compare by to_s
  rule ExpectStringEqual, "puts ary # => [1]",
       {code: "ary", eq: "[1]"}

  # compare by eq when it includes '# =>'
  rule ExpectEqual, "value # => 2",
       {code: "value", eq: "2"}

  # pp
  rule Nop, "pp a # => \"1\""

  # default
  rule Nop, "1"
end
