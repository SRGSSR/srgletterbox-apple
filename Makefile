#!/usr/bin/xcrun make -f

CARTHAGE_FOLDER=Carthage
CARTHAGE_FLAGS=--platform iOS --cache-builds --new-resolver

CARTFILE_HIDDEN=Cartfile.hidden
CARTFILE_PROPRIETARY=Cartfile.proprietary
CARTFILE_PRIVATE=Cartfile.private

CARTFILE_RESOLVED=Cartfile.resolved
CARTFILE_RESOLVED_CLOSED=Cartfile.resolved.closed
CARTFILE_RESOLVED_OPEN=Cartfile.resolved.open

RESTORE_CARTFILE_RESOLVED_CLOSED=@[ -f $(CARTFILE_RESOLVED_CLOSED) ] && cp $(CARTFILE_RESOLVED_CLOSED) $(CARTFILE_RESOLVED) || true
RESTORE_CARTFILE_RESOLVED_OPEN=@[ -f $(CARTFILE_RESOLVED_OPEN) ] && cp $(CARTFILE_RESOLVED_OPEN) $(CARTFILE_RESOLVED) || true

SAVE_CARTFILE_RESOLVED_CLOSED=@mv $(CARTFILE_RESOLVED) $(CARTFILE_RESOLVED_CLOSED)
SAVE_CARTFILE_RESOLVED_OPEN=@mv $(CARTFILE_RESOLVED) $(CARTFILE_RESOLVED_OPEN)

CREATE_CARTFILE_PRIVATE_CLOSED=@(cat $(CARTFILE_HIDDEN); echo) > $(CARTFILE_PRIVATE); cat $(CARTFILE_PROPRIETARY) >> $(CARTFILE_PRIVATE)
CREATE_CARTFILE_PRIVATE_OPEN=@cp $(CARTFILE_HIDDEN) $(CARTFILE_PRIVATE)

CLEAN_CARTFILE_PRIVATE=@rm -f $(CARTFILE_PRIVATE)

.PHONY: all
all: bootstrap
	@echo "Building the project..."
	@xcodebuild build
	@echo ""

# Resolving dependencies without building the project

.PHONY: update_dependencies
update_dependencies: update_dependencies_open
	@echo "Updating $(CARTFILE_RESOLVED_CLOSED) dependencies..."
	$(CREATE_CARTFILE_PRIVATE_CLOSED)
	@carthage update $(CARTHAGE_FLAGS) --no-build
	$(SAVE_CARTFILE_RESOLVED_CLOSED)
	$(CLEAN_CARTFILE_PRIVATE)
	@echo ""

.PHONY: update_dependencies_open
update_dependencies_open:
	@echo "Updating $(CARTFILE_RESOLVED_OPEN) dependencies..."
	$(CREATE_CARTFILE_PRIVATE_OPEN)
	@carthage update $(CARTHAGE_FLAGS) --no-build
	$(SAVE_CARTFILE_RESOLVED_OPEN)
	$(CLEAN_CARTFILE_PRIVATE)
	@echo ""

# Dependency compilation with proprietary dependencies

.PHONY: bootstrap
bootstrap:
	@echo "Building dependencies declared in $(CARTFILE_RESOLVED_CLOSED)..."
	$(CREATE_CARTFILE_PRIVATE_CLOSED)
	$(RESTORE_CARTFILE_RESOLVED_CLOSED)
	@carthage bootstrap $(CARTHAGE_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_CLOSED)
	$(CLEAN_CARTFILE_PRIVATE)
	@echo ""

# Also keep open source build dependencies in sync
.PHONY: update
update: update_dependencies_open
	@echo "Updating and building $(CARTFILE_RESOLVED_CLOSED) dependencies..."
	$(CREATE_CARTFILE_PRIVATE_CLOSED)
	@carthage update $(CARTHAGE_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_CLOSED)
	$(CLEAN_CARTFILE_PRIVATE)
	@echo ""

# Open source dependency compilation

.PHONY: bootstrap_open
bootstrap_open:
	@echo "Building dependencies declared in $(CARTFILE_RESOLVED_OPEN)..."
	$(CREATE_CARTFILE_PRIVATE_OPEN)
	$(RESTORE_CARTFILE_RESOLVED_OPEN)
	@carthage bootstrap $(CARTHAGE_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_OPEN)
	$(CLEAN_CARTFILE_PRIVATE)
	@echo ""

.PHONY: update_open
update_open:
	@echo "Updating and building $(CARTFILE_RESOLVED_OPEN) dependencies..."
	$(CREATE_CARTFILE_PRIVATE_OPEN)
	@carthage update $(CARTHAGE_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_OPEN)
	$(CLEAN_CARTFILE_PRIVATE)
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
