To launch:

1. Create .env file, follow .env.example
2. `go mod download`
3. `go run ./app`

OR

1. Create .env file, follow .env.example. This file will be used to set env variables inside the docker container.
2. `docker-compose up --build`

Optionally, generate swagger docs with

`swag init --dir . --generalInfo ./app/main.go --output ./docs`

![Database architecture diagram](docs/diagram.png)

OR pull the docker container

`docker pull 0bochina/backend:latest`