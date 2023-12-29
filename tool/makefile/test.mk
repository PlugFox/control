.PHONY: integration test

integration:
	@(cd example && flutter test \
		--coverage \
		integration_test/app_test.dart)

test:
	@flutter test test/control_test.dart
