# comment-spec.cr

Comment driven spec builder for [Crystal](http://crystal-lang.org/).

- crystal: 0.20.3

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  comment-spec:
    github: maiha/comment-spec.cr
    version: 0.1.0
```

## Usage

```crystal
require "comment-spec"

CommentSpec.parse("1 + 2 # => 3") # => "( 1 + 2 ).should eq( 3 )"
```

## Development

## Contributing

1. Fork it ( https://github.com/maiha/comment-spec.cr/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [maiha](https://github.com/maiha) maiha - creator, maintainer
