#!/bin/bash

# Set debug mode for verbose output
DEBUG=true

# Function to print debug information
print_debug() {
  if [ "$DEBUG" = true ]; then
    echo -e "[DEBUG] $1"
  fi
}

# Function to print colored messages
RED='\033[0;31m'
NC='\033[0m' # No Color

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a command exists
check_command() {
  if ! command -v "$1" &> /dev/null; then
    print_error "$1 is required but not installed."
    exit 1
  fi
}

# Function to find an available port starting from the given port
find_available_port() {
  local port=$1
  local max_attempts=10
  local attempt=0
  
  # Check if lsof command exists
  if ! command -v lsof &> /dev/null; then
    echo "[WARNING] lsof command not found, using default port $port"
    echo "$port"
    return 0
  fi
  
  print_debug "Searching for available port starting from $port (max attempts: $max_attempts)"
  
  while [ $attempt -lt $max_attempts ]; do
    print_debug "Checking port $port (attempt $((attempt+1))/$max_attempts)"
    
    # Try to connect to the port
    if ! lsof -i:"$port" > /dev/null 2>&1; then
      print_debug "Port $port is available"
      echo "$port"
      return 0
    else
      print_debug "Port $port is in use, trying next port"
    fi
    
    port=$((port + 1))
    attempt=$((attempt + 1))
  done

  print_error "Could not find an available port after $max_attempts attempts"
  exit 1
}

# Test the function
print_debug "Testing port finder..."
PORT=$(find_available_port 3456)
echo "Found available port: $PORT"