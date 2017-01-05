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
    version: 0.2.2
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
