package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sns"
)

// {
//   "name": "Harrison",
//   "location": "Home",
//   "event": "ARRIVE" // ARRIVE | LEAVE
// }
type LocationChangePayload struct {
	Name     string `json:"name"`
	Location string `json:"location"`
	Event    string `json:"event"`
}

var AWS_TOPIC_ARN string = os.Getenv("AWS_TOPIC_ARN")
var MESSAGE_GROUP_ID string = os.Getenv("MESSAGE_GROUP_ID")

func HandleLocationChange(ctx context.Context, data LocationChangePayload) error {
	// Initialize a session that the SDK will use to load
	// credentials from the shared credentials file. (~/.aws/credentials).
	sess := session.Must(session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	}))

	svc := sns.New(sess)

	b, err := json.Marshal(data)
	if err != nil {
		return err
	}
	str := string(b)

	result, err := svc.Publish(&sns.PublishInput{
		Message:        &str,
		TopicArn:       &AWS_TOPIC_ARN,
		MessageGroupId: &MESSAGE_GROUP_ID,
	})
	if err != nil {
		return err
	}

	fmt.Println(*result.MessageId)

	return nil
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(HandleLocationChange)
}
