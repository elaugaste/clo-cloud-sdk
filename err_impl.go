package clo_cloud_sdk

import "fmt"

func (e ApiError) Error() string {
	if e.Code != 0 {
		if e.Description != "" {
			return fmt.Sprintf("API Error [%d]: %s (%s)", e.Code, e.Message, e.Description)
		}
		return fmt.Sprintf("API Error [%d]: %s", e.Code, e.Message)
	}
	return fmt.Sprintf("API Error: %s", e.Message)
}
