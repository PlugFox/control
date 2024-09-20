.PHONY: integration
integration:  ## Run integration tests
				@(cd example && flutter test \
					--coverage \
					integration_test/app_test.dart) || (echo "Error while running integration tests"; exit 1)

.PHONY: test
test:  ## Run unit tests
				@flutter test test/control_test.dart --coverage || (echo "Error while running tests"; exit 1)
				@genhtml coverage/lcov.info --output=.coverage -o .coverage/html || (echo "Error while running unit tests"; exit 2)

.PHONY: genhtml
genhtml: ## Generate coverage html
				@genhtml coverage/lcov.info -o coverage/html || (echo "Error while running genhtml"; exit 1)
