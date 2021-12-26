package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/aws/aws-lambda-go/events"
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

type MessagePayload struct {
	Name         string `json:"name"`
	LocationName string `json:"location_name"`
}

func handler(ctx context.Context, sqsEvent events.SQSEvent) error {
	bot, err := tgbotapi.NewBotAPI(botToken)
	if err != nil {
		return err
	}

	bot.Debug = true

	log.Printf("Authorized on account %s", bot.Self.UserName)

	var payload MessagePayload

	for _, message := range sqsEvent.Records {
		json.Unmarshal([]byte(message.Body), &payload)

		messageText := fmt.Sprintf("%s is at %s", payload.Name, payload.LocationName)
		msg := tgbotapi.NewMessage(channelID, messageText)
		bot.Send(msg)
	}

	return nil
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(handler)
}
