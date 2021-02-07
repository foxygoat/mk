# Build, test and check coverage for Go programs

GO = go
GO_CMDS = $(if $(wildcard ./cmd/*),./cmd/...,.)

build: | $(O)  ## Build binaries of directories in ./cmd to out/
	go build -o $(O) -ldflags='$(GO_LDFLAGS)' $(GO_CMDS)

install:  ## Build and install binaries in $GOBIN or $GOPATH/bin
	go install -ldflags='$(GO_LDFLAGS)' $(GO_CMDS)


.PHONY: build install

COVERFILE = $(O)/coverage.txt

test: ## Run tests and generate a coverage file
	go test -coverprofile=$(COVERFILE) ./...

check-coverage: test  ## Check that test coverage meets the required level
	@go tool cover -func=$(COVERFILE) | $(CHECK_COVERAGE) || $(FAIL_COVERAGE)

cover: test  ## Show test coverage in your browser
	go tool cover -html=$(COVERFILE)

CHECK_COVERAGE = awk -F '[ \t%]+' '/^total:/ {print; if ($$3 < $(COVERAGE)) exit 1}'
FAIL_COVERAGE = { echo '$(COLOUR_RED)FAIL - Coverage below $(COVERAGE)%$(COLOUR_NORMAL)'; exit 1; }

.PHONY: check-coverage cover test

GOLINT_VERSION ?= 1.33.2
GOLINT_INSTALLED_VERSION = $(or $(word 4,$(shell golangci-lint --version 2>/dev/null)),0.0.0)
GOLINT_USE_INSTALLED = $(filter $(GOLINT_INSTALLED_VERSION),v$(GOLINT_VERSION) $(GOLINT_VERSION))
GOLINT = $(if $(GOLINT_USE_INSTALLED),golangci-lint,golangci-lint-v$(GOLINT_VERSION))

GOBIN ?= $(firstword $(subst :, ,$(GOPATH)))/bin

lint: $(if $(GOLINT_USE_INSTALLED),,$(GOBIN)/$(GOLINT))  ## Lint source code
	$(GOLINT) run

$(GOBIN)/$(GOLINT):
	cd /tmp; \
	GOBIN=/tmp GO111MODULE=on go get github.com/golangci/golangci-lint/cmd/golangci-lint@v$(GOLINT_VERSION); \
	mv /tmp/golangci-lint $@

.PHONY: lint
