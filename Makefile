#!/usr/bin/xcrun make -f

CARTHAGE_FOLDER=Carthage
CARTHAGE_RESOLUTION_FLAGS=--new-resolver --no-build
CARTHAGE_BUILD_FLAGS=--platform iOS --cache-builds

CARTFILE_PRIVATE=Cartfile.private
CARTFILE_PRIVATE_COMMON=Cartfile.private.common
CARTFILE_PRIVATE_PROPRIETARY=Cartfile.private.proprietary
CARTFILE_PRIVATE_PUBLIC=Cartfile.private.public

CARTFILE_RESOLVED=Cartfile.resolved
CARTFILE_RESOLVED_PROPRIETARY=Cartfile.resolved.proprietary
CARTFILE_RESOLVED_PUBLIC=Cartfile.resolved.public

RESTORE_CARTFILE_PRIVATE_COMMON=@rm -f $(CARTFILE_PRIVATE);[ -f $(CARTFILE_PRIVATE_COMMON) ] && cat $(CARTFILE_PRIVATE_COMMON) >> $(CARTFILE_PRIVATE) || true
RESTORE_CARTFILE_PRIVATE_PROPRIETARY=@$(RESTORE_CARTFILE_PRIVATE_COMMON);[ -f $(CARTFILE_PRIVATE_PROPRIETARY) ] && (echo; cat $(CARTFILE_PRIVATE_PROPRIETARY)) >> $(CARTFILE_PRIVATE) || true
RESTORE_CARTFILE_PRIVATE_PUBLIC=@$(RESTORE_CARTFILE_PRIVATE_COMMON);[ -f $(CARTFILE_PRIVATE_PUBLIC) ] && (echo; cat $(CARTFILE_PRIVATE_PUBLIC)) >> $(CARTFILE_PRIVATE) || true

RESTORE_CARTFILE_RESOLVED_PROPRIETARY=@[ -f $(CARTFILE_RESOLVED_PROPRIETARY) ] && cp $(CARTFILE_RESOLVED_PROPRIETARY) $(CARTFILE_RESOLVED) || true
RESTORE_CARTFILE_RESOLVED_PUBLIC=@[ -f $(CARTFILE_RESOLVED_PUBLIC) ] && cp $(CARTFILE_RESOLVED_PUBLIC) $(CARTFILE_RESOLVED) || true

SAVE_CARTFILE_RESOLVED_PROPRIETARY=@[ -f $(CARTFILE_RESOLVED) ] && cp $(CARTFILE_RESOLVED) $(CARTFILE_RESOLVED_PROPRIETARY) || true
SAVE_CARTFILE_RESOLVED_PUBLIC=@[ -f $(CARTFILE_RESOLVED) ] && cp $(CARTFILE_RESOLVED) $(CARTFILE_RESOLVED_PUBLIC) || true

.PHONY: all
all: bootstrap
	@echo "Building the project..."
	@xcodebuild build
	@echo ""

# Resolving dependencies without building the project

.PHONY: dependencies
dependencies: public.dependencies
	@echo "Updating $(CARTFILE_RESOLVED_PROPRIETARY) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_PROPRIETARY)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PROPRIETARY)
	@echo ""

.PHONY: public.dependencies
public.dependencies:
	@echo "Updating $(CARTFILE_RESOLVED_PUBLIC) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_PUBLIC)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PUBLIC)
	@echo ""

# Dependency compilation with proprietary dependencies

.PHONY: bootstrap
bootstrap:
	@echo "Building dependencies declared in $(CARTFILE_RESOLVED_PROPRIETARY)..."
	$(RESTORE_CARTFILE_PRIVATE_PROPRIETARY)
	$(RESTORE_CARTFILE_RESOLVED_PROPRIETARY)
	@carthage bootstrap $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PROPRIETARY)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	@echo ""

# Also keep public build dependencies in sync
.PHONY: update
update: public.dependencies
	@echo "Updating and building $(CARTFILE_RESOLVED_PROPRIETARY) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_PROPRIETARY)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PROPRIETARY)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	@echo ""

# Public dependency compilation

.PHONY: public.bootstrap
public.bootstrap:
	@echo "Building dependencies declared in $(CARTFILE_RESOLVED_PUBLIC)..."
	$(RESTORE_CARTFILE_PRIVATE_PUBLIC)
	$(RESTORE_CARTFILE_RESOLVED_PUBLIC)
	@carthage bootstrap $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PUBLIC)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	@echo ""

.PHONY: public.update
public.update:
	@echo "Updating and building $(CARTFILE_RESOLVED_PUBLIC) dependencies..."
	$(RESTORE_CARTFILE_PRIVATE_PUBLIC)
	@carthage update $(CARTHAGE_RESOLUTION_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_PUBLIC)
	@carthage build $(CARTHAGE_BUILD_FLAGS)
	@echo ""

# Framework package to attach to github releases

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
	@echo ""

.PHONY: help
help:
	@echo "The following targets must be used for proprietary builds:"
	@echo "   all                         Build project dependencies and the project"
	@echo "   dependencies                Update dependencies without building them"
	@echo "   bootstrap                   Build dependencies as declared in $(CARTFILE_RESOLVED_PROPRIETARY)"
	@echo "   update                      Update and build dependencies"
	@echo "   package                     Build and package the framework for attaching to github releases"
	@echo ""
	@echo "The following targets must be used when building the public source code:"
	@echo "   public.dependencies         Update dependencies without building them"
	@echo "   public.bootstrap            Build dependencies as declared in $(CARTFILE_RESOLVED_PUBLIC)"
	@echo "   public.update               Update and build dependencies"
	@echo ""
	@echo "The following targets are widely available:"
	@echo "   help                        Display this message"
	@echo "   clean                       Clean the project and its dependencies"
