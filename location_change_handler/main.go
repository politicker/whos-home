package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/aws/aws-lambda-go/events"
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

var AWS_TOPIC_ARN string = os.Getenv("AWS_TOPIC_ARN")
var MESSAGE_GROUP_ID string = os.Getenv("MESSAGE_GROUP_ID")

func serverError(err error) (events.APIGatewayProxyResponse, error) {
	log.Println(err)

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusInternalServerError,
		Body:       err.Error(),
	}, err
}

func HandleLocationChange(ctx context.Context, data events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	log.Println("HandleLocationChange -> Starting", data.Body)

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

	uid, err := uuid.NewV4()
	if err != nil {
		return serverError(err)
	}
	dedupeID := uid.String()

	_, err = svc.Publish(&sns.PublishInput{
		Message:                &data.Body,
		TopicArn:               &AWS_TOPIC_ARN,
		MessageGroupId:         &MESSAGE_GROUP_ID,
		MessageDeduplicationId: &dedupeID,
	})
	if err != nil {
		return serverError(err)
	}

	log.Println("HandleLocationChange -> Finished")

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusCreated,
		Body:       "created sns event",
	}, nil
}

func main() {
	// Make the handler available for Remote Procedure Call by AWS Lambda
	lambda.Start(HandleLocationChange)
}
