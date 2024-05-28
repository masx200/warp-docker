package main

import (
	"net/http"
)

func main() {
	for {
		code := request("http://1.1.1.1/")
		if code == 301 || code == 200 {
			break
		}
	}
}
func request(url string) int {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return 0
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return 0
	}
	defer resp.Body.Close()
	return resp.StatusCode
}
