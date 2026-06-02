.PHONY: setup generate packages open

# Regenerate the Xcode project from project.yml.
generate:
	xcodegen generate

# Download and lock Swift package dependencies (run after generate or when Xcode shows "Missing package product").
packages:
	xcodebuild -resolvePackageDependencies -project Rivalo.xcodeproj -scheme Rivalo

# Full local setup: generate project + resolve packages.
setup: generate packages

open: setup
	open Rivalo.xcodeproj
