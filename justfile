set dotenv-load := true

run-subscriber:
	cd publisher && cargo r

run:
	cd subscriber && cargo r

# terraform plan
plan:
	cd terraform && terraform plan

# deploy a named lambda
publish function:
	#!/usr/bin/env bash
	set -euxo pipefail

	just \
		--working-directory functions/{{ function }} \
		--justfile ./functions.justfile \
		build package upload-cmd

# initialize a named lambda. Should be run only once
create function:
	#!/usr/bin/env bash
	set -euxo pipefail

	just \
		--working-directory functions/{{ function }} \
		--justfile ./functions.justfile \
		build package create-cmd cleanup

test-telegram:
	cd telegram-test && go run main.go

test-publish:
	#!/usr/bin/env bash
	set -euxo pipefail

	aws sns publish \
		--region us-east-2 \
		--topic-arn arn:aws:sns:us-east-2:114418550400:whos_home.fifo \
		--message-group-id "$(echo $RANDOM | md5sum | head -c 2)" \
		--message-deduplication-id "$(echo $RANDOM | md5sum | head -c 2)" \
		--message '{"name": "Quinn", "location": "Home", "event": "ARRIVING"}'
