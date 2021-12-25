set dotenv-load := true

run:
	cargo r

plan:
	cd terraform && terraform plan

build-macos:
	cd arrivals_handler && \
	cargo build --release --target x86_64-unknown-linux-musl

build-linux:
	cd arrivals_handler && \
	cargo build --release

package:
	zip -j function.zip ./target/x86_64-unknown-linux-musl/release/bootstrap

package-linux:
	zip -j function.zip ./target/x86_64-unknown-linux-musl/release/bootstrap

publish: build-macos package
	aws create-function \
	--role whos_home_lambda \
	--function-name location_change_handler \
	--runtime provided.al2 \
	--package-type Zip \
	--zip-file function.zip

publish-linux: build-linux package-linux
	aws create-function \
	--role whos_home_lambda \
	--function-name location_change_handler \
	--runtime provided.al2 \
	--package-type Zip \
	--zip-file function.zip
