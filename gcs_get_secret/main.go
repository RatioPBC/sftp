package main

import (
	"context"
	"flag"
	"fmt"
	"log"

	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
)

type config struct {
	ProjectID string
	Secret    string
}

func parseFlags() config {
	cfg := config{}
	flag.StringVar(&cfg.ProjectID, "p", "", "project-id")
	flag.StringVar(&cfg.Secret, "s", "", "secret")
	flag.Parse()

	if cfg.ProjectID == "" {
		log.Fatal("-p/--project-id flag required")
	}

	if cfg.ProjectID == "" {
		log.Fatal("-s/--secret flag required")
	}

	return cfg
}

func main() {
	cfg := parseFlags()

	ctx := context.Background()
	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		log.Fatalf("failed to setup client: %v", err)
	}
	defer client.Close()

	secretName := fmt.Sprintf("projects/%s/secrets/%s/versions/latest", cfg.ProjectID, cfg.Secret)
	accessRequest := &secretmanagerpb.AccessSecretVersionRequest{Name: secretName}

	result, err := client.AccessSecretVersion(ctx, accessRequest)
	if err != nil {
		log.Fatalf("failed to access secret version: %v", err)
	}

	fmt.Printf("%s", result.Payload.Data)
}
