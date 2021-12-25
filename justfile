set dotenv-load := true

run:
	cargo r

plan:
	cd terraform && terraform plan

build:
	cd arrivals_handler && \
	cargo build --release --target x86_64-unknown-linux-musl

package:
	cd arrivals_handler && \
	zip -j function.zip ./target/x86_64-unknown-linux-musl/release/bootstrap

publish: build package
	cd arrivals_handler && \
	aws lambda create-function \
	--role "arn:aws:iam::114418550400:role/whos_home_lambda" \
	--function-name location_change_handler \
	--runtime provided.al2 \
	--handler bootstrap \
	--package-type Zip \
	--zip-file fileb://function.zip
