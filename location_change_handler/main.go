package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/sns"
	uuid "github.com/nu7hatch/gouuid"
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

type LocationChangeResponse struct {
	IsBase64Encoded bool              `json:"isBase64Encoded"`
	StatusCode      int               `json:"statusCode"`
	Headers         map[string]string `json:"headers"`
	Body            string            `json:"body"`
}

var AWS_TOPIC_ARN string = os.Getenv("AWS_TOPIC_ARN")
var MESSAGE_GROUP_ID string = os.Getenv("MESSAGE_GROUP_ID")

func serverError(err error) (LocationChangeResponse, error) {
	log.Println(err)

	return LocationChangeResponse{
		StatusCode: http.StatusInternalServerError,
		Body:       err.Error(),
	}, err
}

func HandleLocationChange(ctx context.Context, data LocationChangePayload) (LocationChangeResponse, error) {
	log.Println("hello from logsz")

	if AWS_TOPIC_ARN == "" {
		err := fmt.Errorf("missing AWS_TOPIC_ARN environment variable")
		return serverError(err)
	}
	if MESSAGE_GROUP_ID == "" {
		err := fmt.Errorf("missing MESSAGE_GROUP_ID environment variable")
		return serverError(err)
	}

	// Initialize a session that the SDK will use to load
	// credentials from the shared credentials file. (~/.aws/credentials).
	sess, err := session.NewSessionWithOptions(session.Options{
		SharedConfigState: session.SharedConfigEnable,
	})
	if err != nil {
		return serverError(err)
	}
	svc := sns.New(sess)

	b, err := json.Marshal(data)
	if err != nil {
		return serverError(err)
	}
	str := string(b)

	uid, err := uuid.NewV4()
	if err != nil {
		return serverError(err)
	}
	dedupeID := uid.String()

	result, err := svc.Publish(&sns.PublishInput{
		Message:                &str,
		TopicArn:               &AWS_TOPIC_ARN,
		MessageGroupId:         &MESSAGE_GROUP_ID,
		MessageDeduplicationId: &dedupeID,
	})
	if err != nil {
		return serverError(err)
	}

	fmt.Println(*result.MessageId)
	log.Println("Finished executing successfully.")

	return LocationChangeResponse{
		StatusCode: http.StatusCreated,
		Body:       "created sns event",
	}, nil
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(HandleLocationChange)
}
