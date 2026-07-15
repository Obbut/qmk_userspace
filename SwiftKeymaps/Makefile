# Host-only documentation tooling. Firmware builds are owned directly by QMK
# through users/obbut_keymap/rules.mk and never invoke this Makefile.

SWIFT ?= swift
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILD_DIR ?= $(ROOT)/.build-docs

.PHONY: all qmk-keymap-docs docs clean

all: qmk-keymap-docs

qmk-keymap-docs:
	$(SWIFT) build \
		--package-path $(ROOT) \
		--scratch-path $(BUILD_DIR) \
		--product qmk-keymap-docs

docs:
	$(SWIFT) run \
		--package-path $(ROOT) \
		--scratch-path $(BUILD_DIR) \
		qmk-keymap-docs $(ARGS)

clean:
	rm -rf $(BUILD_DIR)
