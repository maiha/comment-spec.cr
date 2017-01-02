macro rule(regex, klass, value = nil, &block)
  CommentSpec::Rules << CommentSpec::Rule.new({{regex}},
    ->(line : String, md : Regex::MatchData) {
      {% if block %}
        CommentSpec::{{klass}}.new(line, {{yield}}).as(CommentSpec::Builder)
      {% else %}
        CommentSpec::{{klass}}.new(line, {{value}}).as(CommentSpec::Builder)
      {% end %}
    })
end

class CommentSpec
  Rules = [] of Rule

  record Rule, pattern : Regex, builder : Proc(String, Regex::MatchData, Builder) do
    def builder?(line : String) : Builder?
      line.match(pattern).try{|md| builder.call(line, md)}
    end
  end
end
