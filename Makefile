#!/usr/bin/xcrun make -f

CARTHAGE_FOLDER=Carthage
CARTHAGE_RESOLUTION_FLAGS=--new-resolver --no-build
CARTHAGE_BUILD_FLAGS=--platform iOS --cache-builds

CARTFILE_PRIVATE=Cartfile.private
CARTFILE_PRIVATE_COMMON=Cartfile.private.common
CARTFILE_PRIVATE_CLOSED=Cartfile.private.closed
CARTFILE_PRIVATE_OPEN=Cartfile.private.open

CARTFILE_RESOLVED=Cartfile.resolved
CARTFILE_RESOLVED_CLOSED=Cartfile.resolved.closed
CARTFILE_RESOLVED_OPEN=Cartfile.resolved.open

RESTORE_CARTFILE_PRIVATE_COMMON=@[ -f $(CARTFILE_PRIVATE_COMMON) ] && cp $(CARTFILE_PRIVATE_COMMON) $(CARTFILE_PRIVATE) || touch $(CARTFILE_PRIVATE_COMMON)
RESTORE_CARTFILE_PRIVATE_CLOSED=$(RESTORE_CARTFILE_PRIVATE_COMMON);[ -f $(CARTFILE_PRIVATE_CLOSED) ] && (echo; cat $(CARTFILE_PRIVATE_CLOSED)) >> $(CARTFILE_PRIVATE) || true
RESTORE_CARTFILE_PRIVATE_OPEN=$(RESTORE_CARTFILE_PRIVATE_COMMON);[ -f $(CARTFILE_PRIVATE_OPEN) ] && (echo; cat $(CARTFILE_PRIVATE_OPEN)) >> $(CARTFILE_PRIVATE) || true

CLEAN_CARTFILE_PRIVATE=@rm -f $(CARTFILE_PRIVATE)

RESTORE_CARTFILE_RESOLVED_CLOSED=@[ -f $(CARTFILE_RESOLVED_CLOSED) ] && cp $(CARTFILE_RESOLVED_CLOSED) $(CARTFILE_RESOLVED) || true
RESTORE_CARTFILE_RESOLVED_OPEN=@[ -f $(CARTFILE_RESOLVED_OPEN) ] && cp $(CARTFILE_RESOLVED_OPEN) $(CARTFILE_RESOLVED) || true

SAVE_CARTFILE_RESOLVED_CLOSED=@[ -f $(CARTFILE_RESOLVED) ] && cp $(CARTFILE_RESOLVED) $(CARTFILE_RESOLVED_CLOSED) || true
SAVE_CARTFILE_RESOLVED_OPEN=@[ -f $(CARTFILE_RESOLVED) ] && cp $(CARTFILE_RESOLVED) $(CARTFILE_RESOLVED_OPEN) || true

CLEAN_CARTFILE_RESOLVED=@rm -f $(CARTFILE_RESOLVED)

.PHONY: all
all: bootstrap
	@echo "Building the project..."
	@xcodebuild build
	@echo ""

# Resolving dependencies without building the project

.PHONY: update_dependencies
update_dependencies: update_dependencies_open
	@echo "Updating $(CARTFILE_RESOLVED_CLOSED) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_CLOSED)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_CLOSED)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

.PHONY: update_dependencies_open
update_dependencies_open:
	@echo "Updating $(CARTFILE_RESOLVED_OPEN) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_OPEN)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_OPEN)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

# Dependency compilation with proprietary dependencies

.PHONY: bootstrap
bootstrap:
	@echo "Building dependencies declared in $(CARTFILE_RESOLVED_CLOSED)..."
	$(RESTORE_CARTFILE_PRIVATE_CLOSED)
	$(RESTORE_CARTFILE_RESOLVED_CLOSED)
	@carthage bootstrap $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_CLOSED)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	$(CLEAN_CARTFILE_PRIVATE)
	@echo ""

# Also keep open source build dependencies in sync
.PHONY: update
update: update_dependencies_open
	@echo "Updating and building $(CARTFILE_RESOLVED_CLOSED) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_CLOSED)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_CLOSED)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

# Open source dependency compilation

.PHONY: bootstrap_open
bootstrap_open:
	@echo "Building dependencies declared in $(CARTFILE_RESOLVED_OPEN)..."
	$(RESTORE_CARTFILE_PRIVATE_OPEN)
	$(RESTORE_CARTFILE_RESOLVED_OPEN)
	@carthage bootstrap $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_OPEN)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	$(CLEAN_CARTFILE_PRIVATE)
	@echo ""

.PHONY: update_open
update_open:
	@echo "Updating and building $(CARTFILE_RESOLVED_OPEN) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_OPEN)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_OPEN)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

# Framework package to attach to github releases. Only for proprietary builds (open source builds
# can use these binaries as well).

.PHONY: package
package: bootstrap
	@echo "Packaging binaries..."
	@mkdir -p archive
	@carthage build --no-skip-current
	@carthage archive --output archive
	@echo ""

# Cleanup

.PHONY: clean
clean:
	@echo "Cleaning up build products..."
	@xcodebuild clean
	@rm -rf $(CARTHAGE_FOLDER)
	$(CLEAN_CARTFILE_PRIVATE)
	$(CLEAN_CARTFILE_RESOLVED)
	@echo ""

.PHONY: help
help:
	@echo "The following targets must be used with proprietary builds:"
	@echo "   all                         Build project dependencies and the project"
	@echo "   update_dependencies         Update dependencies without building them"
	@echo "   bootstrap                   Build dependencies as declared in $(CARTFILE_RESOLVED_CLOSED)"
	@echo "   update                      Update and build dependencies"
	@echo "   package                     Build and package the framework for attaching to github releases"
	@echo ""
	@echo "The following targets must be used with open source builds:"
	@echo "   update_dependencies_open    Update dependencies without building them"
	@echo "   bootstrap_open              Build dependencies as declared in $(CARTFILE_RESOLVED_OPEN)"
	@echo "   update_open                 Update and build dependencies"
	@echo ""
	@echo "The following targets are widely available:"
	@echo "   help                        Display this message"
	@echo "   clean                       Clean the project and its dependencies"
