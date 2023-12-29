.PHONY: version doctor clean get upgrade upgrade-major outdated dependencies format analyze check

# Check flutter version
version:
	@flutter --version

# Check flutter doctor
doctor:
	@flutter doctor

# Clean all generated files
clean:
	@rm -rf coverage .dart_tool .packages pubspec.lock

# Get dependencies
get:
	@flutter pub get

fix: format
	@dart fix --apply lib

# Generate all
gen: codegen

# Upgrade dependencies
upgrade:
	@flutter pub upgrade

# Upgrade to major versions
upgrade-major:
	@flutter pub upgrade --major-versions

# Check outdated dependencies
outdated: get
	@flutter pub outdated

# Check outdated dependencies
dependencies: upgrade
	@flutter pub outdated --dependency-overrides \
		--dev-dependencies --prereleases --show-all --transitive

# Format code
format:
	@dart format --fix -l 80 .

# Analyze code
analyze: get format
	@dart analyze --fatal-infos --fatal-warnings

# Check code
check: analyze test
	@dart pub publish --dry-run
	@dart pub global activate pana
	@pana --json --no-warning --line-length 80 > log.pana.json

# Publish package
publish:
	@dart pub publish
