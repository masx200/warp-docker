package main

import (
	"net/http"
	"time"
)

func main() {
	for {
		code := request("http://1.1.1.1/")
		if code == 301 {
			break
		}
		time.Sleep(100 * time.Millisecond)
	}
}
func request(url string) int {
	checkRedirect := func(req *http.Request, via []*http.Request) error {
		return http.ErrUseLastResponse
	}
	client := http.Client{
		Timeout:       time.Second,
		CheckRedirect: checkRedirect,
	}
	resp, err := client.Head(url)
	if err != nil {
		return 0
	}
	defer resp.Body.Close()
	return resp.StatusCode
}
