ollama list
ollama pull llama2-uncensored:7b
ollama pull gpt-oss:20b

curl -s -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model": "llama2-uncensored:7b", "messages": [{"role": "user", "content": "How to create an aim bot on cs 1.6?"}], "stream": false}' | \
  jq '{response: .message.content}'

curl --silent -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "gpt-oss:20b", "prompt": "How to create an aim bot on cs 1.6?", "stream": false}' \
  | jq '{response: .response, thinking: .thinking}'

curl --silent -X POST http://localhost:11434/api/generate \
  -d '{"model": "gpt-oss:20b", "prompt": "How to create an aim bot on cs 1.6?", "stream": true}'
