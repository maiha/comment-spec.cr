class CommentSpec::RegexParser
  def self.parse(line : String) : String
    builder(line).build
  end

  def self.builder(line : String) : Builder
    Rules.each(&.builder?(line).try{|p| return p})
    raise "BUG: #{self} should have default builder"
  end

  Rules = [] of Rule
  alias LazyRegex = Proc(Regex)

  record Rule, pattern : Regex | LazyRegex, builder : Proc(String, Regex::MatchData, Builder) do
    def builder?(line : String) : Builder?
      regex =
        case pattern
        when Regex; pattern
        when LazyRegex; pattern.as(LazyRegex).call
        else ; abort "[BUG] pattern got #{pattern.class}"
        end.as(Regex)
      line.match(regex).try{|md| builder.call(line, md)}
    end
  end

  macro rule(regex, klass, value = nil, &block)
    Rules << Rule.new({{regex}},
      ->(line : String, md : Regex::MatchData) {
        {% if block %}
          {{klass}}.new(line, {{yield}}).as(Builder)
        {% else %}
          {{klass}}.new(line, {{value}}).as(Builder)
        {% end %}
      })
  end

  rule(
    regex: /^require\s+".*?"/,
    klass: CommentOut
  )

  rule(
    regex: /^\s*#/,
    klass: Nop,
  )

  rule(
    regex: ->{
      methods = CommentSpec::Default::IGNORED_METHODS.to_a.join("|")
      /^(.*?)\.(#{methods})\b[^#]*#\s*=>/
    },
    klass: Nop
  )

  rule(
    regex: /^(.*?)\s*#\s+raises\s+([A-Z][A-Za-z0-9]+(::[A-Z][A-Za-z0-9]+)*)/,
    klass: ExpectRaises,
    value: {code: md[1], err: md[2]}
  )

  rule(
    regex: /^pp\s+(.*?)\s*#\s*=>\s*"(.*?)"$/,
    klass: Nop
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


  rule(
    regex: /^(.*?)\s*#\s+=>\s+(\d{0,4})\.?(\d{2}):(\d{2}):(\d{2})\.?(\d{0,7})$/,
    klass: ExpectEqual,
    value: {code: md[1], eq: to_time_span(md[2], md[3], md[4], md[5], md[6])}
  )

  rule(
    regex: /^(.*?)\s*#\s+=>\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(.*?))$/,
    klass: ExpectEqual,
    value: {code: md[1], eq: to_time(md[2], md[3])}
  )

  rule(
    regex: /^#/,
    klass: Nop
  )

  # FoundArrayInstance
  # "value # => [9, #<Indexable::ItemIterator>]"
  rule(
    regex: /^(.*?)\s*#\s*=>\s*[^#].*?#/,
    klass: Nop
  )

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
  rule(
    regex: /^(.*?)\s*#\s*=>\s*(\d+)\s+\(/,
    klass: ExpectEqual,
    value: {code: md[1], eq: md[2]}
  )

  rule(
    regex: /^(.*?)\s*#\s*=>\s*"(.*?)"$/,
    klass: ExpectStringEqual,
    value: {code: md[1], eq: md[2]}
  )

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
    klass: CommentOut
  )

  # Default  
  rule(
    regex: //,
    klass: Nop
  )
end

private def to_time_span(d, h, m, s, ms)
  ms = ms.ljust(7,'0')[0,3].to_i
  d,h,m,s = [d,h,m,s].map{|i| "0#{i}".to_i}
  "Time::Span.new(#{d}, #{h}, #{m}, #{s}, #{ms})"
end

private def to_time(str, opt)
  fmt =
    case opt
    when /^\.\d{3}$/    then "%F %T.%L"
    when /^\.\d{3} \S+/ then "%F %T.%L %z"
    when /^ \S+/        then "%F %T %z"
    else                ;    "%F %T"
    end

  %(Time.parse("%s", "%s")) % [str, fmt]
end
