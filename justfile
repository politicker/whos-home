set dotenv-load := true

run:
	cargo r

plan:
	cd terraform && terraform plan

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
		--function-name location_change_handler \
		--zip-file fileb://function.zip \
		--publish

create-cmd:
	aws lambda create-function \
	--role "arn:aws:iam::114418550400:role/whos_home_lambda" \
	--function-name location_change_handler \
	--handler main \
	--runtime go1.x \
	--package-type Zip \
	--zip-file fileb://function.zip

publish function:
	#!/usr/bin/env bash
	set -euxo pipefail

	just \
		--working-directory {{ function }} \
		--justfile ./justfile \
		build package upload-cmd cleanup

create function:
	#!/usr/bin/env bash
	set -euxo pipefail

	just \
		--working-directory {{ function }} \
		--justfile ./justfile \
		build package create-upload-cmd cleanup
