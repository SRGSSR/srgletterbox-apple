#!/usr/bin/xcrun make -f

CONFIGURATION_FOLDER=Configuration
CONFIGURATION_COMMIT_SHA1=8b914063814a47e81918acbda7326e80d72fb687

# Checkout a commit for a repository in the specified directory. Fails if the repository is dirty of if the
# commit does not exist.  
#   Syntax: $(call checkout_repository,directory,commit)
define checkout_repository
	@cd $(1); \
	if [[ `git status --porcelain` ]]; then \
		echo "The repository '$(1)' contains changes. Please commit or discard these changes and retry."; \
		exit 1; \
	elif `git fetch; git checkout -q $(2)`; then \
		exit 0; \
	else \
		echo "The repository '$(1)' could not be switched to commit $(2). Does this commit exist?"; \
		exit 1; \
	fi;
endef

.PHONY: all
all: test-ios test-tvos

.PHONY: test-ios
test-ios:
	@echo "Running iOS unit tests..."
	@xcodebuild test -scheme SRGLetterbox -destination 'platform=iOS Simulator,name=iPhone 11' 2> /dev/null
	@echo "... done.\n"

.PHONY: test-tvos
test-tvos:
	@echo "Running tvOS unit tests..."
	@xcodebuild test -scheme SRGLetterbox -destination 'platform=tvOS Simulator,name=Apple TV' 2> /dev/null
	@echo "... done.\n"

.PHONY: setup
setup:
	@echo "Setting up the project..."

	@if [ ! -d $(CONFIGURATION_FOLDER) ]; then \
		git clone https://github.com/SRGSSR/srgletterbox-apple-configuration.git $(CONFIGURATION_FOLDER); \
	else \
		echo "A $(CONFIGURATION_FOLDER) folder is already available."; \
	fi;
	$(call checkout_repository,$(CONFIGURATION_FOLDER),$(CONFIGURATION_COMMIT_SHA1))
	
	@ln -fs $(CONFIGURATION_FOLDER)/.env
	@mkdir -p Xcode/Links
	@pushd Xcode/Links > /dev/null; ln -fs ../../$(CONFIGURATION_FOLDER)/Xcode/*.xcconfig .
	@echo "... done.\n"

.PHONY: public.setup
public.setup:
	@echo "Setting up the project..."

	@mkdir -p Xcode/Links
	@pushd Xcode/Links > /dev/null; ln -fs ../Public/*.xcconfig .
	@echo "... done.\n"

.PHONY: help
help:
	@echo "The following targets are available:"
	@echo "   setup               Setup project (internal SRG SSR use)"
	@echo "   public.setup        Setup project (public)"
	@echo "   all                 Build and run unit tests for all platforms"
	@echo "   test-ios            Build and run unit tests for iOS"
	@echo "   test-tvos           Build and run unit tests for tvOS"
	@echo "   help                Display this help message"