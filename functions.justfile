set dotenv-load := true

build:
	#!/usr/bin/env bash
	set -euxo pipefail

	GOOS=linux go build main.go

package:
	zip -j function.zip ./main

cleanup:
	rm function.zip && \
	rm main

upload-cmd:
	aws lambda update-function-code \
		--region us-east-2 \
		--function-name `basename $(pwd)` \
		--zip-file fileb://function.zip \
		--publish

create-cmd:
	aws lambda create-function \
		--region us-east-2 \
		--role "arn:aws:iam::114418550400:role/whos_home_lambda" \
		--function-name `basename $(pwd)` \
		--handler main \
		--runtime go1.x \
		--package-type Zip \
		--zip-file fileb://function.zip
