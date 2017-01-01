private macro rule(name, regex, action)
  Rules << Rule.new({{name.stringify}}, {{regex}}, {{action}})
end

class CommentSpec
  Rules = [] of Rule

  private record Rule, name : String, pattern : Regex, builder : Proc(String, Regex::MatchData, Builder) do
    def builder?(line : String) : Builder?
      line.match(pattern).try{|md| builder.call(line, md)}
    end
  end
  
  rule Require, /^require\s+".*?"/,
    ->(line : String, md : Regex::MatchData) {
      CommentOut.new(line, nil).as(Builder)
    }

  rule Dynamic, /^(.*?)\.(object_id|mtime|hash|sample|to_utc|to_local|local_offset_in_minutes)\b[^#]*#\s*=>/,
    ->(line : String, md : Regex::MatchData) {
      Nop.new(line, nil).as(Builder)
    }

  rule Raises , /^(.*?)\s*#\s+raises\s+([A-Z][A-Za-z0-9]+(::[A-Z][A-Za-z0-9]+)*)/,
    ->(line : String, md : Regex::MatchData) {
      ExpectRaises.new(line, {code: md[1], err: md[2]}).as(Builder)
    }

  rule FoundPP, /^pp\s+(.*?)\s*#\s*=>\s*"(.*?)"$/,
    ->(line : String, md : Regex::MatchData) {
      Nop.new(line, nil).as(Builder)
    }
  
  rule FoundPuts, /^puts\s+(.*?)\s*#\s*=>\s*"?(.*?)"?$/,
    ->(line : String, md : Regex::MatchData) {
      ExpectStringEqual.new(line, {code: md[1], eq: md[2].strip}).as(Builder)
    }
  
  # NOTE: check with `class.to_s` for the case of private class like `Indexable::ItemIterator`
  rule ReturnClass, /^(.*?)\s*#\s*=>\s+#<([A-Z][A-Za-z0-9]+(::[A-Z][A-Za-z0-9]+)*).*?>/,
    ->(line : String, md : Regex::MatchData) {
      ExpectClass.new(line, {code: md[1], eq: md[2]}).as(Builder)
    }
  #      "( #{$1} ).class.to_s.should eq( \"#{$2}\" )"

  rule ReturnTimeSpan, /^(.*?)\s*#\s+=>\s+(\d{0,4})\.?(\d{2}):(\d{2}):(\d{2})\.?(\d{0,7})$/,
    ->(line : String, md : Regex::MatchData) {
      ms = md[6].ljust(7,'0')[0,3].to_i
      d,h,m,s = [md[2],md[3],md[4],md[5]].map(&.sub(/^0/, ""))
      d  = 0 if d.empty?
      eq = "Time::Span.new(#{d}, #{h}, #{m}, #{s}, #{ms})"
      ExpectEqual.new(line, {code: md[1], eq: eq}).as(Builder)
    }
  
  rule ReturnTime, /^(.*?)\s*#\s+=>\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(.*?))$/,
    ->(line : String, md : Regex::MatchData) {
      code, str, rest = md[1], md[2], md[3]
      fmt = "%F %T" + build_time_optional_format(rest)
      eq = "Time.parse(\"#{str}\", \"#{fmt}\")"
      ExpectEqual.new(line, {code: md[1], eq: eq}).as(Builder)
    }

  rule CommentOnly, /^#/,
    ->(line : String, md : Regex::MatchData) {
      Nop.new(line, nil).as(Builder)
    }
  
  # "value # => [9, #<Indexable::ItemIterator>]"
  rule ArrayInstance, /^(.*?)\s*#\s*=>\s*[^#].*?#/,
    ->(line : String, md : Regex::MatchData) {
      Nop.new(line, nil).as(Builder)
    }

  rule EmptyCollection, /^(.*?)\s*#\s*=>\s*(\[\]|\[\[\]\]|{})$/,
    ->(line : String, md : Regex::MatchData) {
      ExpectStringEqual.new(line, {code: md[1], eq: md[2]}).as(Builder)
    }

  rule FoundFloat, /^(.*?)\s*#\s*=>\s*(\d+\.\d+)$/,
    ->(line : String, md : Regex::MatchData) {
    data = {code: md[1], eq: md[2]}
      if md[1] =~ /\.to_f\??$/
        ExpectStringEqual.new(line, data).as(Builder)
      else
        ExpectTryFloat.new(line, data).as(Builder)
      end
    }

  rule FoundNumeric, /^(.*?)\s*#\s*=>\s*(\d+)\s+\(/,
    ->(line : String, md : Regex::MatchData) {
      ExpectEqual.new(line, {code: md[1], eq: md[2]}).as(Builder)
    }
  
  rule FoundString, /^(.*?)\s*#\s*=>\s*"(.*?)"$/,
    ->(line : String, md : Regex::MatchData) {
      ExpectStringEqual.new(line, {code: md[1], eq: md[2]}).as(Builder)
    }
  
  rule FoundLiteral, /^(.*?)\s*#\s*=>\s*(\d{20,}|\d+\/\d+|BitArray\[.*?|.*?\d+\.\d+i|CSV::Token.*?)$/,
    ->(line : String, md : Regex::MatchData) {
      v = md[2].gsub(/"/, %(\\"))
      ExpectStringEqual.new(line, {code: md[1], eq: v}).as(Builder)
    }

  rule FoundSomething, /^(.*?)\s*#\s*=>\s*(.*?)$/,
    ->(line : String, md : Regex::MatchData) {
      ExpectEqual.new(line, {code: md[1], eq: md[2]}).as(Builder)
    }
  
  rule CompilationError, /#.*?(error|exception)/i,
    ->(line : String, md : Regex::MatchData) {
      CommentOut.new(line, nil).as(Builder)
    }
  
  rule Nop, //,
    ->(line : String, md : Regex::MatchData) {
      Nop.new(line, nil).as(Builder)
    }
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
