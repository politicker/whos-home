package main

import (
	"log"

	"github.com/aws/aws-lambda-go/lambda"
	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
)

var channelID int64 = -1001608175662
var botToken string = "5002335179:AAHBzgbAc73LglnhYbDpp8lcZx1IeHuKi6c"

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
