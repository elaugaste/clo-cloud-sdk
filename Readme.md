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
	resp, _ := client.ProjectServerListV2ProjectsObjectIdServersGetWithResponse(ctx, cloProject)

	for _, server := range *resp.JSON200.Result {
		logger.Info("Server found", slog.String("server_name", server.Name))
	}

}
```

### Result
```
{"time":"2026-01-24T06:03:50.981860791+05:00","level":"INFO","msg":"HTTP request processed","method":"GET","url":"https://api.clo.ru/v2/projects/ed23f80e-6584-4679-a76a-640c1f9904c9/servers","duration":667168371,"status":200}
{"time":"2026-01-24T06:03:50.98252569+05:00","level":"INFO","msg":"Server found","server_name":"vpn"}
{"time":"2026-01-24T06:03:50.982537892+05:00","level":"INFO","msg":"Server found","server_name":"chirpstack"}
{"time":"2026-01-24T06:03:50.982540792+05:00","level":"INFO","msg":"Server found","server_name":"dh-test"}
{"time":"2026-01-24T06:03:50.982542792+05:00","level":"INFO","msg":"Server found","server_name":"k8s-ctrl13"}
```