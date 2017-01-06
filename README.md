# comment-spec.cr [![Build Status](https://travis-ci.org/maiha/comment-spec.cr.svg?branch=master)](https://travis-ci.org/maiha/comment-spec.cr)

Comment driven spec builder for [Crystal](http://crystal-lang.org/).

- This **is** a spec string generator.
- This **is not** a kind of spec tools.
- crystal: 0.20.3

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  comment-spec:
    github: maiha/comment-spec.cr
    version: 0.3.0
```

## Usage

```crystal
require "comment-spec"

CommentSpec.parse "1 + 2 # => 3"                   # => "( 1 + 2 ).should eq( 3 )"
CommentSpec.parse "value # => 2016-03-31 12:36:21" # => "( value ).should eq( Time.parse(\"2016-03-31 12:36:21\", \"%F %T\") )"
CommentSpec.parse "v[10] # raises IndexError"      # => "expect_raises(IndexError) { v[10] }"
CommentSpec.parse "value # => #<XXX>"              # => "( value ).class.to_s.should eq( \"XXX\" )"
```

## Converting Rules

- rule: [src/comment-spec/lexer_parser.cr](./src/comment-spec/lexer_parser.cr)
- spec: [spec/fixtures/](./spec/fixtures/)

## Restrictions

This library is a **line based** parser. So, following partial code is processed as is.

```
  ...
end # => [1,2]
```

## Strategies

This library extract a comment from source by using three parsers.

#### 1. `LexerParser` : Strictly parser

This parses the code by using `Crystal::Lexer`. Although this can strictly parse codes, therefore it would raise error when the case of partial or invalid codes.

```
struct Foo # a some comment here
# or
[] # raises error
```

`Crystal::Parser` would fail with unexpected `:EOF`.

#### 2. `RegexParser` : Roughly parser

This parses the code by using `Regex`. This simply scans a code with `/#/` and split it into **code** and **comment**. So, somtimes the parsing result would be wrong, but never fails.

#### 3. `CommentSpec` : Hybrid Parser

This basically uses `LexerParser` and fallback with `RegexParser`. So, it's easy to use for API because `CommentSpec.parse(line)` can parse almost codes with best effort.

## Development

```shell
make spec
```

## Contributing

1. Fork it ( https://github.com/maiha/comment-spec.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer
