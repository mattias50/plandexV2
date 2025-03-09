
# Set strict error handling
set -e

# Enable debug mode for verbose output
DEBUG=true

# Function to print debug information
print_debug() {
  if [ "$DEBUG" = true ]; then
    echo -e "[DEBUG] $1"
  fi
}

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# Function to print environment information
print_environment_info() {
  print_debug "=== Environment Information ==="
  print_debug "Working directory: $(pwd)"
  print_debug "User: $(whoami)"
  print_debug "Shell: $SHELL"
  print_debug "PATH: $PATH"
  print_debug "GOPATH: $GOPATH"
  print_debug "GOROOT: $GOROOT"
  print_debug "GO111MODULE: $GO111MODULE"
  print_debug "=== End Environment Information ==="
}

# Function to print context information
print_context_info() {
  print_debug "=== Context Information ==="
  print_debug "CLI_DIR: $CLI_DIR"
  print_debug "SERVER_DIR: $SERVER_DIR"
  print_debug "SHARED_DIR: $SHARED_DIR"
  
  if [ -d "$CLI_DIR" ]; then
    print_debug "CLI directory exists"
    if [ -f "$CLI_DIR/go.mod" ]; then
      print_debug "CLI go.mod exists"
    else
      print_debug "CLI go.mod does not exist"
    fi
  else
    print_debug "CLI directory does not exist"
  fi
  
  if [ -d "$SERVER_DIR" ]; then
    print_debug "Server directory exists"
    if [ -f "$SERVER_DIR/go.mod" ]; then
      print_debug "Server go.mod exists"
    else
      print_debug "Server go.mod does not exist"
    fi
  else
    print_debug "Server directory does not exist"
  fi
  
  if [ -d "$SHARED_DIR" ]; then
    print_debug "Shared directory exists"
    if [ -f "$SHARED_DIR/go.mod" ]; then
      print_debug "Shared go.mod exists"
    else
      print_debug "Shared go.mod does not exist"
    fi
  else
    print_debug "Shared directory does not exist"
  fi
  
  print_debug "=== End Context Information ==="
}

# Function to check if a command exists
check_command() {
  if ! command -v "$1" &> /dev/null; then
    print_error "$1 is required but not installed."
    exit 1
  fi
}

# Check for required tools
check_command go
check_command git

# Function to find an available port starting from the given port
find_available_port() {
  local port=$1
  local max_attempts=10
  local attempt=0

  while [ $attempt -lt $max_attempts ]; do
    if ! lsof -i:"$port" > /dev/null 2>&1; then
      echo "$port"
      return 0
    fi
    port=$((port + 1))
    attempt=$((attempt + 1))
  done

  print_error "Could not find an available port after $max_attempts attempts"
  exit 1
}

# Set working directories
CLI_DIR="app/cli"
SERVER_DIR="app/server"
SHARED_DIR="app/shared"

# Print environment and context information
print_environment_info
print_context_info

# Check for common issues that might cause nil pointer dereference
check_nil_pointer_issues() {
  print_debug "Checking for potential nil pointer issues..."
  
  # Check if context_update.go exists
  if [ ! -f "$CLI_DIR/lib/context_update.go" ]; then
    print_warning "context_update.go file not found at $CLI_DIR/lib/context_update.go"
    return 1
  fi
  
  # Check for potential nil pointer issues in context_update.go
  print_debug "Checking context_update.go for potential nil pointer issues..."
  grep -n "req\[" "$CLI_DIR/lib/context_update.go" | while read -r line; do
    print_debug "Potential nil pointer access: $line"
  done
  
  # Check if the UpdateContext function has nil checks
  if grep -q "if req == nil" "$CLI_DIR/lib/context_update.go"; then
    print_debug "Found nil check for req in context_update.go"
  else
    print_warning "No nil check for req found in context_update.go"
  fi
  
  return 0
}

# Set working directories
CLI_DIR="app/cli"
SERVER_DIR="app/server"
SHARED_DIR="app/shared"

# Parse command line arguments
SKIP_TESTS=false
RUN_SERVER=false
RUN_CLI=false
BUILD_ONLY=false
CLEAN=false
SKIP_NIL_CHECK=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --skip-tests)
      SKIP_TESTS=true
      shift
      ;;
    --server)
      RUN_SERVER=true
      shift
      ;;
    --cli)
      RUN_CLI=true
      shift
      ;;
    --build-only)
      BUILD_ONLY=true
      shift
      ;;
    --clean)
      CLEAN=true
      shift
      ;;
    --skip-nil-check)
      SKIP_NIL_CHECK=true
      shift
      ;;
    --debug)
      DEBUG=true
      shift
      ;;
    --no-debug)
      DEBUG=false
      shift
      ;;
    *)
      print_error "Unknown option: $1"
      echo "Available options: --skip-tests, --server, --cli, --build-only, --clean, --skip-nil-check, --debug, --no-debug"
      exit 1
      ;;
  esac
done

# If no specific component is selected, build and run both
if [ "$RUN_SERVER" = false ] && [ "$RUN_CLI" = false ] && [ "$BUILD_ONLY" = false ]; then
  RUN_SERVER=true
  RUN_CLI=true
fi

# Clean build artifacts if requested
if [ "$CLEAN" = true ]; then
  print_message "Cleaning build artifacts..."
  
  # Clean CLI build artifacts
  if [ -d "$CLI_DIR/bin" ]; then
    rm -rf "$CLI_DIR/bin"
  fi
  
  # Clean server build artifacts
  if [ -d "$SERVER_DIR/bin" ]; then
    rm -rf "$SERVER_DIR/bin"
  fi
  
  # Clean go cache
  go clean -cache
  
  print_message "Clean completed"
fi

# Build shared package first
print_message "Building shared package..."
cd "$SHARED_DIR" || { print_error "Failed to change directory to $SHARED_DIR"; exit 1; }
go build ./... || { print_error "Failed to build shared package"; exit 1; }
cd - > /dev/null || { print_error "Failed to return to root directory"; exit 1; }

# Run tests for shared package if not skipped
if [ "$SKIP_TESTS" = false ]; then
  print_message "Running tests for shared package..."
  cd "$SHARED_DIR" || { print_error "Failed to change directory to $SHARED_DIR"; exit 1; }
  go test ./... || { print_error "Tests failed for shared package"; exit 1; }
  cd - > /dev/null || { print_error "Failed to return to root directory"; exit 1; }
fi

# Build and run CLI if requested
if [ "$RUN_CLI" = true ] || [ "$BUILD_ONLY" = true ]; then
  print_message "Building CLI..."
  cd "$CLI_DIR" || { print_error "Failed to change directory to $CLI_DIR"; exit 1; }
  
  # Run nil pointer check if not skipped
  if [ "$SKIP_NIL_CHECK" = false ]; then
    print_debug "Running nil pointer check..."
    if ! check_nil_pointer_issues; then
      print_warning "Potential nil pointer issues detected. Use --skip-nil-check to bypass this check."
      print_warning "The nil pointer issue might be in context_update.go around line 226."
      print_warning "Consider adding nil checks for the 'req' parameter before accessing it."
      
      # Ask for confirmation to continue
      read -p "Continue anyway? (y/n) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_message "Exiting as requested."
        exit 0
      fi
    else
      print_debug "No potential nil pointer issues detected."
    fi
  fi
  
  go build -o bin/plandex || { print_error "Failed to build CLI"; exit 1; }
  
  # Run tests for CLI if not skipped
  if [ "$SKIP_TESTS" = false ]; then
    print_message "Running tests for CLI..."
    go test ./... || { print_warning "Some tests failed for CLI"; }
  fi
  
  # Run CLI if requested and not build-only
  if [ "$RUN_CLI" = true ] && [ "$BUILD_ONLY" = false ]; then
    print_message "Running CLI..."
    ./bin/plandex version
  fi
  
  cd - > /dev/null || { print_error "Failed to return to root directory"; exit 1; }
fi

# Build and run server if requested
if [ "$RUN_SERVER" = true ] || [ "$BUILD_ONLY" = true ]; then
  print_message "Building server..."
  cd "$SERVER_DIR" || { print_error "Failed to change directory to $SERVER_DIR"; exit 1; }
  go build -o bin/server || { print_error "Failed to build server"; exit 1; }
  
  # Run tests for server if not skipped
  if [ "$SKIP_TESTS" = false ]; then
    print_message "Running tests for server..."
    go test ./... || { print_warning "Some tests failed for server"; }
  fi
  
  # Run server if requested and not build-only
  if [ "$RUN_SERVER" = true ] && [ "$BUILD_ONLY" = false ]; then
    # Find an available port
    PORT=$(find_available_port 3456)
    print_message "Starting server on port $PORT..."
    
    # Run the server in the background
    PORT=$PORT ./bin/server &
    SERVER_PID=$!
    
    # Give the server a moment to start
    sleep 2
    
    # Check if server is still running
    if kill -0 $SERVER_PID 2>/dev/null; then
      print_message "Server is running with PID $SERVER_PID"
      print_message "Opening browser to http://localhost:$PORT"
      
      # Open browser based on OS
      if command -v xdg-open &> /dev/null; then
        xdg-open "http://localhost:$PORT" &
      elif command -v open &> /dev/null; then
        open "http://localhost:$PORT" &
      else
        print_warning "Could not open browser automatically. Please visit http://localhost:$PORT"
      fi
      
      print_message "Press Ctrl+C to stop the server"
      
      # Wait for Ctrl+C
      wait $SERVER_PID
    else
      print_error "Server failed to start"
      exit 1
    fi
  fi
  
  cd - > /dev/null || { print_error "Failed to return to root directory"; exit 1; }
fi

print_message "All tasks completed successfully!
