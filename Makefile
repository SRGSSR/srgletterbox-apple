#!/usr/bin/xcrun make -f

CONFIGURATION_REPOSITORY_URL=https://github.com/SRGSSR/srgletterbox-apple-configuration.git
CONFIGURATION_COMMIT_SHA1=85e5d0b0731a5ae53296ab78ef566c61e473f6e5
CONFIGURATION_FOLDER=Configuration

.PHONY: all
all: setup test-ios test-tvos

.PHONY: test-ios
test-ios:
	@echo "Running iOS unit tests..."
	@xcodebuild test -scheme SRGLetterbox -destination 'platform=iOS Simulator,name=iPhone 13' 2> /dev/null
	@echo "... done.\n"

.PHONY: test-tvos
test-tvos:
	@echo "Running tvOS unit tests..."
	@xcodebuild test -scheme SRGLetterbox -destination 'platform=tvOS Simulator,name=Apple TV' 2> /dev/null
	@echo "... done.\n"

.PHONY: setup
setup:
	@echo "Setting up the project..."
	@Scripts/checkout-configuration.sh "${CONFIGURATION_REPOSITORY_URL}" "${CONFIGURATION_COMMIT_SHA1}" "${CONFIGURATION_FOLDER}"
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo "   setup           Setup project"
	@echo "   all             Build and run unit tests for all platforms"
	@echo "   test-ios        Build and run unit tests for iOS"
	@echo "   test-tvos       Build and run unit tests for tvOS"
	@echo "   help            Display this help message"