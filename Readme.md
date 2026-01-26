### Example

```
package main

import (
    "context"
    "log/slog"
    "os"
    "time"
    "github.com/Elaugaste/clo-cloud-sdk"
)

func main() {

	cloToken := "your-token-here"
	cloProject := "your-project-id-here"

	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	client, _ := clo_cloud_sdk.NewCLOClient(cloToken,
		clo_cloud_sdk.WithLogger(logger),
		clo_cloud_sdk.WithTimeout(30*time.Second),
	)

	ctx := context.Background()
	resp, err := client.ProjectServerListV2ProjectsObjectIdServersGetWithResponse(ctx, cloProject)
	if err != nil {
		//network err
	}

	if resp.Error != nil {
		//clo api err
		logger.Error(resp.Error.Message,
			slog.Int("status", resp.StatusCode()),
			slog.String("desc",resp.Error.Description))
		return
	}

	for _, server := range *resp.OK.Result {
		logger.Info("Server found", slog.String("server_name", server.Name))
	}

}
```

### Result
```
{"time":"2026-01-26T10:11:51.228297548+05:00","level":"INFO","msg":"HTTP request processed","method":"GET","url":"https://api.clo.ru/v2/projects/ed23f80e-6584-4679-a76a-640c1f9904c9/servers","duration":416856809,"status":200}
{"time":"2026-01-26T10:11:51.230424334+05:00","level":"INFO","msg":"Server found","server_name":"chirpstack"}
{"time":"2026-01-26T10:11:51.230433836+05:00","level":"INFO","msg":"Server found","server_name":"k8s-ctrl13"}
{"time":"2026-01-26T10:11:51.230437736+05:00","level":"INFO","msg":"Server found","server_name":"k8s-worker-4vCPU-4GB-1769391371919359897-0"}

```