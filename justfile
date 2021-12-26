set dotenv-load := true

run:
	cd pi-listener && cargo r

plan:
	cd terraform && terraform plan

publish function:
	#!/usr/bin/env bash
	set -euxo pipefail

	just \
		--working-directory functions/{{ function }} \
		--justfile ./functions.justfile \
		build package upload-cmd cleanup

create function:
	#!/usr/bin/env bash
	set -euxo pipefail

	just \
		--working-directory functions/{{ function }} \
		--justfile ./functions.justfile \
		build package create-cmd cleanup
