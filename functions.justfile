set dotenv-load := true

build:
	#!/usr/bin/env bash
	set -euxo pipefail

	GOOS=linux GOARCH=amd64 go build main.go

package:
	zip main.zip main

cleanup:
	rm main.zip && \
	rm main

upload-cmd:
	aws lambda update-function-code \
		--region us-east-2 \
		--function-name `basename $(pwd)` \
		--zip-file fileb://main.zip \
		--publish

create-cmd:
	aws lambda create-function \
		--region us-east-2 \
		--role "arn:aws:iam::114418550400:role/whos_home_lambda" \
		--function-name `basename $(pwd)` \
		--handler main \
		--runtime go1.x \
		--package-type Zip \
		--zip-file fileb://main.zip
