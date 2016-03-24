# Please refer to http://clarkgrubb.com/makefile-style-guide

# Prologue
MAKEFLAGS += --warn-undefined-variables
SHELL := bash
# SHELLFLAGS has no effect on GNU Make < 3.82
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := all
.DELETE_ON_ERROR:
.SUFFIXES:

minimum_coverage_percent := 100

# TODO: Needs to be removed in Go 1.6 / 1.7
GO15VENDOREXPERIMENT := 1
export GO15VENDOREXPERIMENT

out_test_path := out/test
sources := $(shell find . -type f -name '*.go' -not -path "./vendor/*")

# NOTE that exported variables are available to recipes, but not to shell commands
# Hence passing GO15VENDOREXPERIMENT explicitly to glide
source_directories := $(subst /...,,$(shell GO15VENDOREXPERIMENT=1 glide nv))
all_test_report := $(out_test_path)/all.func.txt
all_test_report_html := $(out_test_path)/all.func.html
top_package_test_reports = $(source_directories:.%=$(out_test_path)/%.func.txt)

.PHONY: all
all: check test

.PHONY: glide.install
glide.install:
	glide install

# create out/test
$(out_test_path):
	@mkdir -p $@

# unit+integration tests
$(out_test_path)/%.func.txt: $(sources)
	@echo "Testing package $*"
	@mkdir -p $(@D)
	@go test -covermode="count" -coverprofile="$@" ./$*
	@touch "$@"

$(out_test_path)/.func.txt: $(sources)
	@echo "Testing package ./"
	@mkdir -p $(@D)
	@go test -covermode="count" -coverprofile="$@" ./
	@touch "$@"

# generate coverage report
$(all_test_report): $(top_package_test_reports)
	@echo "Creating consolidated coverage file $@"
	@{ echo "mode: count"; \
		cat $^ | \
		sed '/^mode.*count$$/d' | sed '/^$$/d' | sed 's/\r$$/$$/' ; } > $@.tmp
	@mv $@.tmp $@

# generate HTML coverage report
$(all_test_report_html): $(all_test_report)
	@go tool cover --html $< -o $@

# verify test coverage
.PHONY: test
test: coverage = $(shell GOPATH=$(GOPATH) go tool cover --func=$(out_test_path)/all.func.txt | tail -1 | awk '{ print int($$3) }' | sed 's/%$$// ')
test: $(all_test_report) $(all_test_report_html)
	$(info Total Coverage = $(coverage)%)
	@if [[ $(coverage) -lt $(minimum_coverage_percent) ]]; then \
		echo "Coverage ${coverage} is below $(minimum_coverage_percent)%! Failing build." ;\
		exit 1 ;\
	fi

# check code format and style
.PHONY: fmt
fmt:
	@echo "Checking formatting of go sources"
	@result=$$(gofmt -d -l -e $(sources) 2>&1); \
		if [[ "$$result" ]]; then \
			echo "$$result"; \
			echo 'gofmt failed!'; \
			exit 1; \
		fi

# Fix code format and style
# NOT TO BE RUN ON BUILD
.PHONY: fixfmt
fixfmt:
	@echo "Fixing format of go sources"
	@gofmt -w -l -e $(sources) 2>&1; \
		if [[ "$$?" != 0 ]]; then \
		    echo "gofmt failed! (exit-code: '$$?')"; \
		    exit 1; \
		fi

.PHONY: vet
vet:
	@echo "Running go vet"
	@go vet $(source_directories)

.PHONY: lint
lint:
	@echo "Running golint"
	@echo $(sources) | xargs -n 1 golint -min_confidence 0.8

.PHONY: check
check: fmt vet lint test

.PHONY: clean
clean:
	@rm -rfv $(out_test_path)
