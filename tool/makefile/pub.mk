.PHONY : version
version: ## Check flutter version
	@flutter --version

.PHONY : doctor
doctor: ## Check flutter doctor
	@flutter doctor

.PHONY : clean
clean: ## Clean all generated files
	@rm -rf coverage .dart_tool .packages pubspec.lock

.PHONY : get
get: ## Get dependencies
	@flutter pub get

.PHONY : fix
fix: format
	@dart fix --apply lib

.PHONY : gen
gen: codegen ## Generate all

.PHONY : upgrade
upgrade: ## Upgrade dependencies
	@flutter pub upgrade

.PHONY : upgrade-major
upgrade-major: ## Upgrade to major versions
	@flutter pub upgrade --major-versions

.PHONY : outdated
outdated: get ## Check outdated dependencies
	@flutter pub outdated

.PHONY : dependencies
dependencies: upgrade ## Check outdated dependencies
	@flutter pub outdated --dependency-overrides \
		--dev-dependencies --prereleases --show-all --transitive

.PHONY : format
format: ## Format code
	@dart format --fix -l 80 .

.PHONY : analyze
analyze: get format ## Analyze code
	@dart analyze --fatal-infos --fatal-warnings

.PHONY : check
check: analyze test ## Check code
	@dart pub publish --dry-run
	@dart pub global activate pana
	@pana --json --no-warning --line-length 80 > log.pana.json

.PHONY : publish
publish: ## Publish package
	@dart pub publish
