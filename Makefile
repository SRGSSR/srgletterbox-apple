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

.PHONY: all update_dependencies update_dependencies_open resolve bootstrap update bootstrap_open update_open package clean

all: bootstrap
	xcodebuild build

# Dependency updates without building the project

update_dependencies:
	$(CREATE_CARTFILE_PRIVATE_CLOSED)
	carthage update $(CARTHAGE_FLAGS) --no-build
	$(SAVE_CARTFILE_RESOLVED_CLOSED)
	$(CLEAN_CARTFILE_PRIVATE)

update_dependencies_open:
	$(CREATE_CARTFILE_PRIVATE_OPEN)
	carthage update $(CARTHAGE_FLAGS) --no-build
	$(SAVE_CARTFILE_RESOLVED_OPEN)
	$(CLEAN_CARTFILE_PRIVATE)

resolve: update_dependencies update_dependencies_open

# Dependency compilation with proprietary dependencies (remark: Keep all dependencies in sync)

bootstrap: update_dependencies_open
	$(CREATE_CARTFILE_PRIVATE_CLOSED)
	$(RESTORE_CARTFILE_RESOLVED_CLOSED)
	carthage bootstrap $(CARTHAGE_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_CLOSED)
	$(CLEAN_CARTFILE_PRIVATE)

update: update_dependencies_open
	$(CREATE_CARTFILE_PRIVATE_CLOSED)
	carthage update $(CARTHAGE_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_CLOSED)
	$(CLEAN_CARTFILE_PRIVATE)

# Open source dependency compilation (remark: Keep all dependencies in sync)

bootstrap_open: update_dependencies
	$(CREATE_CARTFILE_PRIVATE_OPEN)
	$(RESTORE_CARTFILE_RESOLVED_OPEN)
	carthage bootstrap $(CARTHAGE_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_OPEN)
	$(CLEAN_CARTFILE_PRIVATE)

update_open: update_dependencies
	$(CREATE_CARTFILE_PRIVATE_OPEN)
	carthage update $(CARTHAGE_FLAGS)
	$(SAVE_CARTFILE_RESOLVED_OPEN)
	$(CLEAN_CARTFILE_PRIVATE)

# Framework package to attach to github releases. Only for proprietary builds (open source builds
# can use these binaries as well).

package: bootstrap
	mkdir -p archive
	carthage build --no-skip-current
	carthage archive --output archive

# Cleanup

clean:
	xcodebuild clean
	rm -rf $(CARTHAGE_FOLDER)
	$(CLEAN_CARTFILE_PRIVATE)

help:
	@echo "The following targets must be used with proprietary builds:"
	@echo "   all               Build project dependencies and the project"
	@echo "   bootstrap         Build dependencies as declared in $(CARTFILE_RESOLVED_CLOSED)"
	@echo "   update            Update and build dependencies"
	@echo "   package           Build and package the framework for attaching to github releases"
	@echo ""
	@echo "The following targets must be used with open source builds:"
	@echo "   bootstrap_open    Build dependencies as declared in $(CARTFILE_RESOLVED_OPEN)"
	@echo "   update_open       Update and build dependencies"
	@echo ""
	@echo "The following targets are widely available:"
	@echo "   resolve           Resolve dependencies"
	@echo "   help              Display this message"
	@echo "   clean             Clean the project and its dependencies"
