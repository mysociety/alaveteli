#!/bin/bash
echo "Simulating Layer 7 scraper attack..."
echo "1. Sending 12 rapid anonymous requests (expecting 429 on 11th & 12th)..."
for i in {1..12}; do
  curl -i -s http://localhost:3000/country_message | grep -E "HTTP/|RateLimit-"
  sleep 0.1
done

echo "2. Sending 15 requests with verified bot token (expecting all 200 OK)..."
for i in {1..15}; do
  curl -i -s -H "X-FYI-Bot-Token: test_token" http://localhost:3000/country_message | grep -E "HTTP/|RateLimit-"
  sleep 0.1
done
