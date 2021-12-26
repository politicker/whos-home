package main

import (
	"log"

	tgbotapi "github.com/go-telegram-bot-api/telegram-bot-api/v5"
)

var channelID int64 = -1001608175662
var botToken string = "5002335179:AAHBzgbAc73LglnhYbDpp8lcZx1IeHuKi6c"

func main() {
	bot, err := tgbotapi.NewBotAPI(botToken)
	if err != nil {
		log.Panic(err)
	}

	bot.Debug = true

	log.Printf("Authorized on account %s", bot.Self.UserName)

	msg := tgbotapi.NewMessage(channelID, "hi from bot")
	bot.Send(msg)
}
