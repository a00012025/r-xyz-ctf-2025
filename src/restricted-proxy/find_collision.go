package main

import (
	"fmt"
	"math/rand"
	"sync"
	"sync/atomic"
	"time"

	"golang.org/x/crypto/sha3"
)

const (
	charset    = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
	numWorkers = 16
)

var (
	found      int32
	totalTries int64
)

func randomString(length int) string {
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[rand.Intn(len(charset))]
	}
	return string(b)
}

func getSelector(funcSig string) []byte {
	hash := sha3.NewLegacyKeccak256()
	hash.Write([]byte(funcSig))
	return hash.Sum(nil)[:4]
}

func worker(targetSelector []byte, resultChan chan string, wg *sync.WaitGroup) {
	defer wg.Done()

	r := rand.New(rand.NewSource(time.Now().UnixNano()))

	for atomic.LoadInt32(&found) == 0 {
		// Generate random function name
		nameLen := r.Intn(20) + 1
		name := randomString(nameLen)
		funcSig := name + "(uint256)"

		atomic.AddInt64(&totalTries, 1)

		if tries := atomic.LoadInt64(&totalTries); tries%1000000 == 0 {
			fmt.Printf("Tried %d combinations...\n", tries)
		}

		selector := getSelector(funcSig)
		if string(selector) == string(targetSelector) {
			atomic.StoreInt32(&found, 1)
			resultChan <- funcSig
			return
		}
	}
}

func main() {
	rand.Seed(time.Now().UnixNano())

	targetSelector := getSelector("changeWithdrawRate(uint8)")
	fmt.Printf("Target selector: 0x%x\n", targetSelector)

	resultChan := make(chan string)
	var wg sync.WaitGroup

	// Start workers
	for i := 0; i < numWorkers; i++ {
		wg.Add(1)
		go worker(targetSelector, resultChan, &wg)
	}

	// Wait for result
	result := <-resultChan
	fmt.Printf("\nFound collision!\n")
	fmt.Printf("Original: changeWithdrawRate(uint8)\n")
	fmt.Printf("Colliding: %s\n", result)
	fmt.Printf("Selector: 0x%x\n", targetSelector)
	fmt.Printf("Total tries: %d\n", atomic.LoadInt64(&totalTries))
}
