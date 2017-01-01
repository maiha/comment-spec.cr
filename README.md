# comment-spec.cr [![Build Status](https://travis-ci.org/maiha/comment-spec.cr.svg?branch=master)](https://travis-ci.org/maiha/comment-spec.cr)

Comment driven spec builder for [Crystal](http://crystal-lang.org/).

- crystal: 0.20.3

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  comment-spec:
    github: maiha/comment-spec.cr
    version: 0.1.2
```

## Usage

```crystal
require "comment-spec"

line = CommentSpec.new("1 + 2 # => 3") # => #<CommentSpec:0x1ae6ee0>
line.spec                              # => "( 1 + 2 ).should eq( 3 )"
```

## Converting Rules

- [src/comment-spec/rules.cr](./src/comment-spec/rules.cr)

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
