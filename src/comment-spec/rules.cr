private macro rule(name, regex)
  Rules << Rule.new({{name.stringify}}, {{regex}},
    ->(line : String, md : Regex::MatchData) {
      {{yield}}.as(Builder)
    })
end

class CommentSpec
  Rules = [] of Rule

  private record Rule, name : String, pattern : Regex, builder : Proc(String, Regex::MatchData, Builder) do
    def builder?(line : String) : Builder?
      line.match(pattern).try{|md| builder.call(line, md)}
    end
  end
  
  rule CommentRequire, /^require\s+".*?"/ do
    CommentOut.new(line)
  end

  rule FoundDynamic, /^(.*?)\.(object_id|mtime|hash|sample|to_utc|to_local|local_offset_in_minutes)\b[^#]*#\s*=>/ do
    Nop.new(line)
  end

  rule FoundRaises , /^(.*?)\s*#\s+raises\s+([A-Z][A-Za-z0-9]+(::[A-Z][A-Za-z0-9]+)*)/ do
    ExpectRaises.new(line, {code: md[1], err: md[2]})
  end

  rule FoundPP, /^pp\s+(.*?)\s*#\s*=>\s*"(.*?)"$/ do
    Nop.new(line)
  end
  
  rule FoundPuts, /^puts\s+(.*?)\s*#\s*=>\s*"?(.*?)"?$/ do
    ExpectStringEqual.new(line, {code: md[1], eq: md[2].strip})
  end
  
  # NOTE: check with `class.to_s` for the case of private class like `Indexable::ItemIterator`
  rule FoundInstance, /^(.*?)\s*#\s*=>\s+#<([A-Z][A-Za-z0-9]+(::[A-Z][A-Za-z0-9]+)*).*?>/ do
    ExpectClass.new(line, {code: md[1], eq: md[2]})
  end
  #      "( #{$1} ).class.to_s.should eq( \"#{$2}\" )"

  rule FoundTimeSpan, /^(.*?)\s*#\s+=>\s+(\d{0,4})\.?(\d{2}):(\d{2}):(\d{2})\.?(\d{0,7})$/ do
    ms = md[6].ljust(7,'0')[0,3].to_i
    d,h,m,s = [md[2],md[3],md[4],md[5]].map(&.sub(/^0/, ""))
    d  = 0 if d.empty?
    eq = "Time::Span.new(#{d}, #{h}, #{m}, #{s}, #{ms})"
    ExpectEqual.new(line, {code: md[1], eq: eq})
  end
  
  rule FoundTime, /^(.*?)\s*#\s+=>\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(.*?))$/ do
    code, str, rest = md[1], md[2], md[3]
    fmt = "%F %T" + build_time_optional_format(rest)
    eq = "Time.parse(\"#{str}\", \"#{fmt}\")"
    ExpectEqual.new(line, {code: md[1], eq: eq})
  end

  rule FoundCommentOnly, /^#/ do
    Nop.new(line)
  end

  # "value # => [9, #<Indexable::ItemIterator>]"
  rule FoundArrayInstance, /^(.*?)\s*#\s*=>\s*[^#].*?#/ do
    Nop.new(line)
  end

  rule FoundEmptyCollection, /^(.*?)\s*#\s*=>\s*(\[\]|\[\[\]\]|{})$/ do
    ExpectStringEqual.new(line, {code: md[1], eq: md[2]})
  end

  rule FoundFloat, /^(.*?)\s*#\s*=>\s*(\d+\.\d+)$/ do
    data = {code: md[1], eq: md[2]}
    if md[1] =~ /\.to_f\??$/
      ExpectStringEqual.new(line, data)
    else
      ExpectTryFloat.new(line, data)
    end
  end

  rule FoundNumeric, /^(.*?)\s*#\s*=>\s*(\d+)\s+\(/ do
    ExpectEqual.new(line, {code: md[1], eq: md[2]})
  end
  
  rule FoundString, /^(.*?)\s*#\s*=>\s*"(.*?)"$/ do
    ExpectStringEqual.new(line, {code: md[1], eq: md[2]})
  end
  
  rule FoundLiteral, /^(.*?)\s*#\s*=>\s*(\d{20,}|\d+\/\d+|BitArray\[.*?|.*?\d+\.\d+i|CSV::Token.*?)$/ do
    v = md[2].gsub(/"/, %(\\"))
    ExpectStringEqual.new(line, {code: md[1], eq: v})
  end

  rule FoundObject, /^(.*?)\s*#\s*=>\s*(.*?)$/ do
    ExpectEqual.new(line, {code: md[1], eq: md[2]})
  end
  
  rule CompilationError, /#.*?(error|exception)/i do
    CommentOut.new(line, nil)
  end
  
  rule Default, // do
    Nop.new(line)
  end
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
