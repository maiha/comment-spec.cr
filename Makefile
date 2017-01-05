SHELL=/bin/bash

.PHONY : test
test: check_version_mismatch gen_specs spec

.PHONY : spec
spec:
	crystal spec -v --fail-fast

.PHONY : check_version_mismatch
check_version_mismatch: shard.yml README.md
	diff -w -c <(grep version: README.md | head -1) <(grep ^version: shard.yml)

.PHONY : gen_specs
gen_specs: spec/fixtures/master

spec/fixtures/master: doc/fixtures/master examples/fixtures.cr 
	crystal examples/fixtures.cr -- $^ > $@

spec/readme_spec.cr: README.md
	crystal examples/readme.cr
