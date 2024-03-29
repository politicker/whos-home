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
	Message string `json:"Message"`
}

type LocationChangeEvent struct {
	Name     string `json:"name"`
	Location string `json:"location"`
	Event    string `json:"event"`
}

func handler(ctx context.Context, sqsEvent events.SQSEvent) error {
	bot, err := tgbotapi.NewBotAPI(botToken)
	if err != nil {
		return err
	}

	bot.Debug = true

	log.Printf("Authorized on account %s", bot.Self.UserName)

	payload := MessagePayload{}
	event := LocationChangeEvent{}

	for _, message := range sqsEvent.Records {
		json.Unmarshal([]byte(message.Body), &payload)
		json.Unmarshal([]byte(payload.Message), &event)

		var messageText string

		if event.Event == "ARRIVING" {
			messageText = fmt.Sprintf("%s is arriving %s", event.Name, event.Location)
		} else {
			messageText = fmt.Sprintf("%s is leaving %s", event.Name, event.Location)
		}

		msg := tgbotapi.NewMessage(channelID, messageText)
		bot.Send(msg)
	}

	return nil
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(handler)
}
