require "./spec_helper"

private macro expect_rule(klass, line, data = nil)
  it {{line}} do
    builder = CommentSpec::RegexParser.builder({{line}})
    builder.should be_a(CommentSpec::{{klass}})
    builder.data.should eq({{data}}) if {{data}}
  end
end

describe CommentSpec::RegexParser do
  # require
  expect_rule CommentOut, "require \"json\""

  # comment
  expect_rule Nop, "# => 1"
  expect_rule Nop, %(# => #<HTTP::Params @raw_params = {"foo" => ["bar", "baz"]>)

  # dynamic values
  expect_rule Nop, "a.object_id # => 1"
  expect_rule Nop, "file.mtime # => 2015-10-20 13:11:12 UTC"
  expect_rule Nop, "foo.hash # => 1234"
  expect_rule Nop, "a.sample(2) # => [2, 1]"
  expect_rule Nop, "time.to_utc # => xxx"
  expect_rule Nop, "time.to_local # => xxx"
  expect_rule Nop, "time.local_offset_in_minutes # => xxx"

  # raises
  expect_rule ExpectRaises, "value # raises IO::Error",
       {code: "value", err: "IO::Error"}
  expect_rule ExpectRaises, "value # raises IO::Timeout (after 1 second)", # ignore trailing comments
       {code: "value", err: "IO::Timeout"}

  # type
  expect_rule ExpectClass, "value # => #<Foo>",
       {code: "value", eq: "Foo"}
  expect_rule ExpectClass, "value # => #<Iterator::Stop>",
       {code: "value", eq: "Iterator::Stop"}
  expect_rule ExpectClass, "value # => #<Regex::MatchData y>",
       {code: "value", eq: "Regex::MatchData"}
  expect_rule ExpectClass, "value # => #<URI:0x1068a7e40 @port=nil>",
       {code: "value", eq: "URI"}

  # Time::Span
  expect_rule ExpectEqual, "value # => 01:00:00",
       {code: "value", eq: "Time::Span.new(0, 1, 0, 0, 0)"}
  expect_rule ExpectEqual, "value # => 01.02:03:04",
       {code: "value", eq: "Time::Span.new(1, 2, 3, 4, 0)"}
  expect_rule ExpectEqual, "value # => 00:00:00.010",
       {code: "value", eq: "Time::Span.new(0, 0, 0, 0, 10)"}
  
  # Time
  expect_rule ExpectEqual, "value # => 2016-04-05 12:36:21",
       {code: "value", eq: %(Time.parse("2016-04-05 12:36:21", "%F %T"))}

  expect_rule ExpectEqual, "value # => 2016-04-05 12:36:21 UTC",
       {code: "value", eq: %(Time.parse("2016-04-05 12:36:21 UTC", "%F %T %z"))}
  expect_rule ExpectEqual, "value # => 2016-04-05 12:36:21.023 UTC",
       {code: "value", eq: %(Time.parse("2016-04-05 12:36:21.023 UTC", "%F %T.%L %z"))}

  # nop when `=>` found but contains comment
  expect_rule Nop, "value # => [9, #<Indexable::ItemIterator>]"
  # nop when `=>` found but contains no codes
  expect_rule Nop, "# => 1"

  # empty array
  expect_rule ExpectStringEqual, "value # => []",
       {code: "value", eq: "[]"}
  # nested empty array
  expect_rule ExpectStringEqual, "value # => [[]]",
       {code: "value", eq: "[[]]"}
  # empty hash
  expect_rule ExpectStringEqual, "value # => {}",
       {code: "value", eq: "{}"}
  # \d{20,} (BigInt)
  expect_rule ExpectStringEqual, "value # => 12345678912345678912345",
       {code: "value", eq: "12345678912345678912345"}
  # rational
  expect_rule ExpectStringEqual, "value # => 1/6",
       {code: "value", eq: "1/6"}

  # Float
  expect_rule ExpectTryFloat, "value # => 1234.6",
       {code: "value", eq: "1234.6"}
  expect_rule ExpectStringEqual, "value.to_f? # => 1234.6",
       {code: "value.to_f?", eq: "1234.6"}
  
  # string
  expect_rule ExpectStringEqual, "value # => \"BitArray[000000000000]\"",
       {code: "value", eq: "BitArray[000000000000]"}

  # Complex format
  expect_rule ExpectStringEqual, "value # => 1.0 + 0.0i",
       {code: "value", eq: "1.0 + 0.0i"}

  # CSV::Token
  expect_rule ExpectStringEqual, "value # => CSV::Token(@kind=Cell, @value=\"one\")",
       {code: "value", eq: "CSV::Token(@kind=Cell, @value=\\\"one\\\")"}
  
  # Compilation Errors
  expect_rule CommentOut, "[] # syntax error"

  # remove trailing string as comment
  expect_rule ExpectEqual, "value # => 1 (Bob's index)",
       {code: "value", eq: "1"}

  # remove puts and compare by to_s
  expect_rule ExpectStringEqual, "puts ary # => [1]",
       {code: "ary", eq: "[1]"}

  # compare by eq when it includes '# =>'
  expect_rule ExpectEqual, "value # => 2",
       {code: "value", eq: "2"}

  # pp
  expect_rule Nop, "pp a # => \"1\""

  # default
  expect_rule Nop, "1"
end
