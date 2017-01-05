SHELL=/bin/bash

.PHONY : test
test: check_version_mismatch gen spec

.PHONY : spec
spec:
	crystal spec -v --fail-fast

.PHONY : check_version_mismatch
check_version_mismatch: shard.yml README.md
	diff -w -c <(grep version: README.md | head -1) <(grep ^version: shard.yml)

.PHONY : gen
gen: spec/fixtures/master spec/usage_spec.cr

spec/fixtures/master: doc/fixtures/master examples/fixtures.cr 
	crystal examples/fixtures.cr -- $^ > $@

spec/usage_spec.cr: README.md examples/usage.cr
	crystal examples/usage.cr > $@
