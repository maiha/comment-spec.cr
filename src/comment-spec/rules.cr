private macro rule(regex, klass, value)
  Rules << Rule.new("no name", {{regex}},
    ->(line : String, md : Regex::MatchData) {
      {{klass}}.new(line, {{value}}).as(Builder)
    })
end

private macro custom_rule(regex, klass)
  Rules << Rule.new("no name", {{regex}},
    ->(line : String, md : Regex::MatchData) {
      {{klass}}.new(line, {{yield}}).as(Builder)
    })
end

class CommentSpec
  Rules = [] of Rule

  private record Rule, name : String, pattern : Regex, builder : Proc(String, Regex::MatchData, Builder) do
    def builder?(line : String) : Builder?
      line.match(pattern).try{|md| builder.call(line, md)}
    end
  end

  rule(
    regex: /^require\s+".*?"/,
    klass: CommentOut,
    value: nil
  )

  rule(
    regex: /^(.*?)\.(object_id|mtime|hash|sample|to_utc|to_local|local_offset_in_minutes)\b[^#]*#\s*=>/,
    klass: Nop,
    value: nil
  )

  rule(
    regex: /^(.*?)\s*#\s+raises\s+([A-Z][A-Za-z0-9]+(::[A-Z][A-Za-z0-9]+)*)/,
    klass: ExpectRaises,
    value: {code: md[1], err: md[2]}
  )

  rule(
    regex: /^pp\s+(.*?)\s*#\s*=>\s*"(.*?)"$/,
    klass: Nop,
    value: nil
  )
  
  rule(
    regex: /^puts\s+(.*?)\s*#\s*=>\s*"?(.*?)"?$/,
    klass: ExpectStringEqual,
    value: {code: md[1], eq: md[2].strip}
  )
  
  # NOTE: check with `class.to_s` for the case of private class like `Indexable::ItemIterator`
  rule(
    regex: /^(.*?)\s*#\s*=>\s+#<([A-Z][A-Za-z0-9]+(::[A-Z][A-Za-z0-9]+)*).*?>/,
    klass: ExpectClass,
    value: {code: md[1], eq: md[2]}
  )

  custom_rule /^(.*?)\s*#\s+=>\s+(\d{0,4})\.?(\d{2}):(\d{2}):(\d{2})\.?(\d{0,7})$/, ExpectEqual do
    ms = md[6].ljust(7,'0')[0,3].to_i
    d,h,m,s = [md[2],md[3],md[4],md[5]].map(&.sub(/^0/, ""))
    d  = 0 if d.empty?
    eq = "Time::Span.new(#{d}, #{h}, #{m}, #{s}, #{ms})"
    {code: md[1], eq: eq}
  end
  
  custom_rule /^(.*?)\s*#\s+=>\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(.*?))$/, ExpectEqual do
    code, str, rest = md[1], md[2], md[3]
    fmt = "%F %T" + build_time_optional_format(rest)
    eq = "Time.parse(\"#{str}\", \"#{fmt}\")"
    {code: md[1], eq: eq}
  end

  rule /^#/, Nop, nil

  # FoundArrayInstance
  # "value # => [9, #<Indexable::ItemIterator>]"
  rule /^(.*?)\s*#\s*=>\s*[^#].*?#/, Nop, nil

  # FoundEmptyCollection
  rule(
    regex: /^(.*?)\s*#\s*=>\s*(\[\]|\[\[\]\]|{})$/,
    klass: ExpectStringEqual,
    value: {code: md[1], eq: md[2]}
  )
  
  # FoundFloat
  rule(
    regex: /^(.*?\.to_f\??)\s*#\s*=>\s*(\d+\.\d+)$/,
    klass: ExpectStringEqual,
    value: {code: md[1], eq: md[2]}
  )

  rule(
    regex: /^(.*?)\s*#\s*=>\s*(\d+\.\d+)$/,
    klass: ExpectTryFloat,
    value: {code: md[1], eq: md[2]}
  )

  # FoundNumeric
  rule /^(.*?)\s*#\s*=>\s*(\d+)\s+\(/, ExpectEqual, {code: md[1], eq: md[2]}
  
  rule /^(.*?)\s*#\s*=>\s*"(.*?)"$/, ExpectStringEqual, {code: md[1], eq: md[2]}

  # FoundLiteral
  rule(
    regex: /^(.*?)\s*#\s*=>\s*(\d{20,}|\d+\/\d+|BitArray\[.*?|.*?\d+\.\d+i|CSV::Token.*?)$/,
    klass: ExpectStringEqual,
    value: {code: md[1], eq: md[2].gsub(/"/, %(\\"))}
  )

  # FoundObject
  rule(
    regex: /^(.*?)\s*#\s*=>\s*(.*?)$/,
    klass: ExpectEqual,
    value: {code: md[1], eq: md[2]}
  )
  
  # CompilationError
  rule(
    regex: /#.*?(error|exception)/i,
    klass: CommentOut,
    value: nil
  )

  # Default  
  rule //, Nop, nil
end


private def build_time_optional_format(rest)
  case rest
  when /^\.\d{3}$/
    ".%L"
  when /^\.\d{3} \S+/
    ".%L %z"
  when /^ \S+/
    " %z"
  else
    ""
  end
end
