GOLINT = golangci-lint
STATICCHECK = go run honnef.co/go/tools/cmd/staticcheck
GOBINDATA = go run github.com/go-bindata/go-bindata/go-bindata

.PHONY: pre
pre:  ## Install prerequired binary, packages, and other tools
	@mkdir ~/.local/bin -p
	@curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b ~/.local/bin v1.38.0
	@go get honnef.co/go/tools/cmd/staticcheck

.PHONY: all
all: pre test ## Run all check

.PHONY: build
build:  ## Run build
	go build \
		-v -race -trimpath \
	  	-ldflags="-s -w" \
		-o chartify \
		./main.go

.PHONY: install
install:  ## Install the binary
	go install ./cmd/chartify/


.PHONY: lint
lint: verify  ## Perform source code linting
	@echo "performing goimports"
	@goimports -w .
	@echo "running gofumpt"
	@gofumpt -l -w .
	@echo "running golangci-lint"
	@golangci-lint run --issues-exit-code 0 --allow-parallel-runners --print-resources-usage --sort-results --out-format junit-xml > golangci-lint-result.xml


.PHONY: staticcheck
staticcheck: ## Run staticcheck
	$(STATICCHECK) -tests=false ./...

.PHONY: pretest
pretest: lint staticcheck  ## Perform sequence before test run

.PHONY: test
test: ## run the test
	@go test -race ./...

.PHONY: clean
clean:  ## Clean directory from unused data
	rm -rf _tmp chartify

.PHONY: docker-build-dev
docker-build-dev:  ## Build development version of container image
	docker build -t ghcr.io/damarseta/chartify .

.PHONY: docker-test
docker-test: docker-build-dev  ## RUn test inside docker container
	docker run ghcr.io/damarseta/chartify make test

.PHONY: docker-build
docker-build:  ## Build docker container image
	rm -rf _tmp
	mkdir -p _tmp
	CGO_ENABLED=1 go build -a -o _tmp/chartify .
	docker build -t ghcr.io/damarseta/chartify -f Dockerfile.scratch .

.PHONY: install
run: install
	chartify

.PHONY: verify
verify:  ## Tidy & Verify go module
	@go mod tidy
	@go mod verify


.PHONY: help
.DEFAULT_GOAL := help
help:
	@echo  "[!] Available Command: "
	@echo  "-----------------------"
	@grep -h -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
