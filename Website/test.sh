#!/bin/bash

# Hardcoded API key
TOGETHER_API_KEY="794e6a2e9a6545cd402885ab6ce7f2825882d8fd800dc56f94b53bc36ed8caea"

# Ask for user prompt
read -p "Enter your prompt: " user_prompt

# Send POST request and capture response
response=$(curl -s -X POST "https://api.together.xyz/v1/chat/completions" \
  -H "Authorization: Bearer $TOGETHER_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"model\": \"meta-llama/Llama-4-Maverick-17B-128E-Instruct-FP8\",
    \"messages\": [{\"role\": \"user\", \"content\": \"$user_prompt\"}]
  }")

# Print the whole JSON response pretty-printed
echo "$response" | jq .

# OR — just print the assistant's reply (if you want just the message)
echo "Assistant's reply:"
echo "$response" | jq -r '.choices[0].message.content'
