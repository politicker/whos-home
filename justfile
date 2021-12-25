set dotenv-load := true

run:
	cargo r

plan:
	cd terraform && terraform plan

build:
	cd location_change_handler && \
	GOOS=linux go build main.go

package:
	cd location_change_handler && \
	zip -j function.zip ./main

publish: build package
	cd location_change_handler && \
	aws lambda update-function-code \
		--function-name location_change_handler \
		--zip-file fileb://function.zip \
		--publish

create-function:
	cd location_change_handler && \
	aws lambda create-function \
	--role "arn:aws:iam::114418550400:role/whos_home_lambda" \
	--function-name location_change_handler \
	--handler main \
	--runtime go1.x \
	--package-type Zip \
	--zip-file fileb://function.zip
