package main

import (
	"log"
	"os"
	"strconv"

	"github.com/aws/aws-lambda-go/lambda"
	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
)

var channelID int64
var botToken string

func init() {
	channelString := os.Getenv("TELEGRAM_CHANNEL_ID")

	if channelString == "" {
		log.Panicln("env TELEGRAM_CHANNEL_ID undefined")
	}

	botToken = os.Getenv("TELEGRAM_BOT_TOKEN")

	if botToken == "" {
		log.Panicln("env TELEGRAM_BOT_TOKEN undefined")
	}

	channelInt, err := strconv.Atoi(channelString)
	if err != nil {
		log.Panicln("env TELEGRAM_CHANNEL_ID invalid int")
	}

	channelID = int64(channelInt)
}

func Handle() {
	bot, err := tgbotapi.NewBotAPI(botToken)
	if err != nil {
		log.Panic(err)
	}

	bot.Debug = true

	log.Printf("Authorized on account %s", bot.Self.UserName)

	msg := tgbotapi.NewMessage(channelID, "hi from bot")
	bot.Send(msg)
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(Handle)
}
