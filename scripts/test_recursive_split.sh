#!/bin/bash
# Test script to trigger multi-level task splitting
# 
# This script tests that the agent correctly splits complex tasks
# into subtasks, and those subtasks can recursively split further.

set -e

# Check if the server is running
API_URL="${API_URL:-http://127.0.0.1:3000}"
JWT_TOKEN="${JWT_TOKEN:-test-token}"

echo "=== Testing Recursive Task Splitting ==="
echo "API URL: $API_URL"
echo ""

# Function to make authenticated API calls
api_call() {
    local method=$1
    local endpoint=$2
    local data=$3
    
    if [ -n "$data" ]; then
        curl -s -X "$method" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -d "$data" \
            "${API_URL}${endpoint}"
    else
        curl -s -X "$method" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            "${API_URL}${endpoint}"
    fi
}

# Check health
echo "1. Checking server health..."
health=$(curl -s "${API_URL}/api/health")
echo "   Health: $health"
echo ""

# Complex task that should trigger splitting
# This task has multiple independent parts that should be split
COMPLEX_TASK=$(cat <<'EOF'
Build a comprehensive Python utility library with the following features:

1. A file utilities module with:
   - A function to recursively find files by extension
   - A function to calculate directory sizes
   - A function to safely delete files with confirmation

2. A string utilities module with:
   - A function to generate random strings
   - A function to slugify text
   - A function to extract URLs from text

3. A data utilities module with:
   - A function to flatten nested dictionaries
   - A function to deep merge dictionaries
   - A function to convert between JSON and YAML

Each module should have docstrings and type hints.
Create the files in /root/work/test-utils/
EOF
)

echo "2. Submitting complex task..."
echo "   Task: Build Python utility library (should split into ~3 module subtasks)"
echo ""

# Submit the task
response=$(api_call POST "/api/task" "{\"task\": $(echo "$COMPLEX_TASK" | jq -Rs .)}")
task_id=$(echo "$response" | jq -r '.id // empty')

if [ -z "$task_id" ]; then
    echo "   ERROR: Failed to create task. Response: $response"
    exit 1
fi

echo "   Task ID: $task_id"
echo ""

# Poll for completion (with timeout)
echo "3. Waiting for task completion..."
echo "   (Check server logs for 'NodeAgent' entries indicating recursive splitting)"
echo ""

timeout=300  # 5 minute timeout
elapsed=0
interval=5

while [ $elapsed -lt $timeout ]; do
    status_response=$(api_call GET "/api/task/$task_id")
    status=$(echo "$status_response" | jq -r '.status // "unknown"')
    
    echo "   [$elapsed s] Status: $status"
    
    if [ "$status" = "completed" ] || [ "$status" = "Completed" ]; then
        echo ""
        echo "=== Task Completed Successfully ==="
        echo ""
        result=$(echo "$status_response" | jq -r '.result // "No result"')
        echo "Result preview (first 500 chars):"
        echo "$result" | head -c 500
        echo "..."
        echo ""
        
        # Check for recursive execution in result data
        iterations=$(echo "$status_response" | jq -r '.iterations // 0')
        echo "Iterations: $iterations"
        echo ""
        
        # Check logs for splitting evidence
        log_count=$(echo "$status_response" | jq '.log | length')
        echo "Log entries: $log_count"
        exit 0
    elif [ "$status" = "failed" ] || [ "$status" = "Failed" ]; then
        echo ""
        echo "=== Task Failed ==="
        result=$(echo "$status_response" | jq -r '.result // "No result"')
        echo "Error: $result"
        exit 1
    fi
    
    sleep $interval
    elapsed=$((elapsed + interval))
done

echo ""
echo "=== Timeout Reached ==="
echo "Task did not complete within $timeout seconds"
exit 1
