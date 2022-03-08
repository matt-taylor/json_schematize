.PHONY: bash build bundle rspec

APP_NAME?=json_schematize

build: #: Build the containers that we'll need
	docker-compose build --pull

bash: #: Get a bash prompt on the core container
	docker-compose run --rm -e RAILS_ENV=development $(APP_NAME) bash

bash_test: #: Get a test bash prompt on the core container
	docker-compose run --rm -e RAILS_ENV=test $(APP_NAME) bash

down: #: Bring down the service -- Destroys everything in redis and all containers
	docker-compose down

clean: #: Clean up stopped/exited containers
	docker-compose rm -f

bundle: #: install gems for Dummy App with
	docker-compose run --rm $(APP_NAME) bundle install
