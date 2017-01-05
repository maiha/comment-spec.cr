class CommentSpec::Parser < CommentSpec::Lexer
  def self.parse(line, remove_require = true)
    case line
    when /^require /
      return CommentOut.new(line).build if remove_require
    when /# raises.*?(error|exception)/i
    when /#.*?(error|exception)/i # CompilationError
      return CommentOut.new(line).build
    when /^\s*$/, /^#/
      return line
    when /#/
    else
      return line
    end
    return new(line).spec
  end  

  private macro build(klass, value = nil, &block)
    {% if block %}
      return {{klass}}.new(code, {{yield}})
    {% else %}
      return {{klass}}.new(code, {{value}})
    {% end %}
  end

  def builder
    case code
    when /^(.*?)\.(object_id|mtime|hash|sample|to_utc|to_local|local_offset_in_minutes)\b[^#]*#\s*=>/
      # Dynamic Values
      build Nop
    end

    case doc?
    when /^raises\s+([A-Z][A-Za-z0-9]+(::[A-Z][A-Za-z0-9]+)*)/
      build ExpectRaises, {code: code, err: $1}

#    regex: /^pp\s+(.*?)\s*#\s*=>\s*"(.*?)"$/,
#    klass: Nop

#    regex: /^puts\s+(.*?)\s*#\s*=>\s*"?(.*?)"?$/,
#    klass: ExpectStringEqual,
#    value: {code: md[1], eq: md[2].strip}

    when /^=>\s+#<([A-Z][A-Za-z0-9]+(::[A-Z][A-Za-z0-9]+)*).*?>/
      # NOTE: check with `class.to_s` for the case of private class like `Indexable::ItemIterator`
      build ExpectClass, {code: code, eq: $1}

    when /^=>\s+(\d{0,4})\.?(\d{2}):(\d{2}):(\d{2})\.?(\d{0,7})$/
      build ExpectEqual, {code: code, eq: to_time_span($1, $2, $3, $4, $5)}

    when /^=>\s+(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}(.*?))$/
      build ExpectEqual, {code: code, eq: to_time($1, $2)}

    when /^=>\s*[^#].*?#/
      # FoundArrayInstance
      # "value # => [9, #<Indexable::ItemIterator>]"
      build Nop
      
    when /^=>\s*(\[\]|\[\[\]\]|{})$/
      # FoundEmptyCollection
      build ExpectStringEqual, {code: code, eq: $1}

    when /^=>\s*(\d+\.\d+)$/
      # FoundFloat
      data = {code: code, eq: $1}
      if code =~ /\.to_f\??/
        build ExpectStringEqual, data
      else
        build ExpectTryFloat, data
      end

    when /^=>\s*(\d{20,}|\d+\/\d+|BitArray\[.*?|.*?\d+\.\d+i|CSV::Token.*?)$/
      # FoundLiteral
      build ExpectStringEqual, {code: code, eq: $1.gsub(/"/, "\\\"")}

    when /^=>\s*"(.*?)"$/
      build ExpectStringEqual, {code: code, eq: $1}

    when /^=>\s*(.*?)$/
      # FoundObject
      build ExpectEqual, {code: code, eq: $1}

    when /#.*?(error|exception)/i
      # CompilationError
      build CommentOut
      
    when /^=>\s*(\d+)\s+\(/
      # FoundNumeric
      build ExpectEqual, {code: code, eq: $1}

    when /^=>\s*"(.*?)"$/
      build ExpectStringEqual, {code: code, eq: $1}

    when /^=>\s*(.*?)$/
      build ExpectEqual, {code: code, eq: $1}
    end
    
    build Nop
  end

  def spec
    builder.build
  end
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
