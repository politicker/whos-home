set dotenv-load := true

run:
    cargo r

plan:
    cd terraform && terraform plan
