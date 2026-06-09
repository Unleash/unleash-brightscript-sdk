RAWSRC = rawsrc
OUT_DIR = src/main/source
OUT = $(OUT_DIR)/Unleash.brs

# Concatenation order is for readability only; BrightScript resolves function
# definitions at runtime, so order does not affect behavior.
MODULES = \
	UnleashVersion \
	UnleashLogger \
	UnleashUtility \
	UnleashConfig \
	UnleashContext \
	UnleashEvaluation \
	UnleashMetrics \
	UnleashStore \
	UnleashHTTP \
	UnleashClient

.PHONY: help
help: ## Show this help
	@grep -hE '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | sed 's/:.*## /\t/' | column -t -s "$$(printf '\t')"

.PHONY: build
build: ## Concatenate rawsrc modules into the single library file
	@mkdir -p $(OUT_DIR)
	@rm -f $(OUT)
	@for m in $(MODULES); do \
		cat $(RAWSRC)/$$m.brs >> $(OUT); \
		echo "" >> $(OUT); \
	done
	@echo "built $(OUT)"

.PHONY: test
test: build ## Run the off-device unit tests (Node + brs interpreter)
	@node scripts/run-tests.js

.PHONY: lint
lint: ## Type-check / lint with brighterscript
	@./node_modules/.bin/bsc --project bsconfig.json

.PHONY: package
package: build ## Build a sideloadable channel zip
	@rm -rf build/package build/package.zip
	@mkdir -p build/package/source build/package/components
	@cp src/main/manifest build/package/manifest
	@cp src/main/source/main.brs build/package/source/
	@cp src/main/source/Unleash.brs build/package/source/
	@cp src/main/components/* build/package/components/
	@cd build/package && zip -r ../package.zip . >/dev/null
	@echo "built build/package.zip"

# Roku device target for sideloading the demo channel.
# Override on the command line: make install ROKU_IP=192.168.1.50 ROKU_PASS=1234
ROKU_IP ?=
ROKU_PASS ?= rokudev

.PHONY: install
install: package ## Sideload the demo channel to a Roku (set ROKU_IP, ROKU_PASS)
	@test -n "$(ROKU_IP)" || { echo "set ROKU_IP=<your-roku-ip> (and ROKU_PASS=<dev-password>)"; exit 1; }
	@echo "sideloading build/package.zip to $(ROKU_IP) ..."
	@curl -sS --digest -u "rokudev:$(ROKU_PASS)" \
		-F "mySubmit=Install" -F "archive=@build/package.zip" \
		"http://$(ROKU_IP)/plugin_install" \
		| grep -oE "Install Success|Identical|Failed|Application Received" || true

.PHONY: logs
logs: ## Tail the Roku debug console (BrightScript print output)
	@test -n "$(ROKU_IP)" || { echo "set ROKU_IP=<your-roku-ip>"; exit 1; }
	@echo "connecting to $(ROKU_IP):8085 (Ctrl-C to quit) ..."
	@telnet $(ROKU_IP) 8085

# Path to the brs-desktop binary (https://github.com/lvcabral/brs-desktop).
# Override per platform, e.g.:
#   macOS:   make sim BRS_DESKTOP="/Applications/BrightScript Simulator.app/Contents/MacOS/BrightScript Simulator"
#   Linux:   make sim BRS_DESKTOP="$$HOME/Applications/BrightScript Simulator.AppImage"
BRS_DESKTOP ?= BrightScript Simulator

.PHONY: sim
sim: package ## Run the demo in the brs-desktop simulator (-r telnet, -c console)
	@"$(BRS_DESKTOP)" -o build/package.zip -r -c

.PHONY: clean
clean: ## Remove generated artifacts
	@rm -rf build $(OUT)
	@echo "cleaned"
