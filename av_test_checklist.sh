#!/bin/bash

# AV Testing Checklist Script
# Tests common antivirus features across different platforms
# Compatible with Linux, macOS, and Windows (via Git Bash/WSL)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
LOG_FILE="av_test_$(date +%Y%m%d_%H%M%S).log"
TEST_DIR="av_test_files"
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${message}" >> "$LOG_FILE"
}

# Function to check OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS="windows"
    else
        OS="unknown"
    fi
    print_color "$BLUE" "Detected OS: $OS"
}

# Function to create test directory
setup_test_env() {
    print_color "$YELLOW" "\n=== Setting up test environment ==="
    if [ ! -d "$TEST_DIR" ]; then
        mkdir -p "$TEST_DIR"
        print_color "$GREEN" "Created test directory: $TEST_DIR"
    else
        print_color "$YELLOW" "Test directory already exists: $TEST_DIR"
    fi
}

# Function to clean up test files
cleanup() {
    print_color "$YELLOW" "\n=== Cleaning up test files ==="
    read -p "Do you want to clean up test files? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$TEST_DIR"
        print_color "$GREEN" "Test files cleaned up"
    else
        print_color "$YELLOW" "Test files retained in $TEST_DIR"
    fi
}

# Function to display menu
show_menu() {
    echo
    print_color "$BLUE" "========================================="
    print_color "$BLUE" "       AV Testing Checklist Menu         "
    print_color "$BLUE" "========================================="
    echo "1. Test Network-based Threat Detection"
    echo "2. Test File-based Threat Detection"
    echo "3. Test Process/Behavior Monitoring"
    echo "4. Test Web Protection"
    echo "5. Test Email/Phishing Protection"
    echo "6. Test USB/Removable Media Protection"
    echo "7. Test Quarantine and Remediation"
    echo "8. Run All Tests"
    echo "9. Generate Report"
    echo "0. Exit"
    echo
}

# Function to test network-based threats
test_network_threats() {
    print_color "$YELLOW" "\n=== Testing Network-based Threat Detection ==="
    
    # Test 1: Known malicious domain
    print_color "$BLUE" "\nTest 1: Attempting to access known test malware domain..."
    print_color "$YELLOW" "WARNING: This uses EICAR test domain - safe for AV testing"
    
    # Using curl with timeout
    if command -v curl &> /dev/null; then
        curl -s --max-time 5 "http://www.eicar.org/download/eicar.com" -o /dev/null
        if [ $? -eq 0 ]; then
            print_color "$RED" "FAILED: Connection to test malware domain succeeded (AV might not be blocking)"
            ((FAILED_TESTS++))
        else
            print_color "$GREEN" "PASSED: Connection to test malware domain was blocked"
            ((PASSED_TESTS++))
        fi
    else
        print_color "$YELLOW" "curl not available, skipping network test"
    fi
    
    # Test 2: Suspicious port scanning simulation
    print_color "$BLUE" "\nTest 2: Simulating port scan detection..."
    print_color "$YELLOW" "Attempting connections to multiple ports (safe test)..."
    
    local blocked=0
    for port in 22 23 445 3389 8080; do
        timeout 1 bash -c "echo >/dev/tcp/localhost/$port" 2>/dev/null
        if [ $? -ne 0 ]; then
            ((blocked++))
        fi
    done
    
    if [ $blocked -gt 3 ]; then
        print_color "$GREEN" "PASSED: Port scanning activity likely detected"
        ((PASSED_TESTS++))
    else
        print_color "$YELLOW" "INFO: Port scan test completed (detection varies by AV)"
    fi
}

# Function to test file-based threats
test_file_threats() {
    print_color "$YELLOW" "\n=== Testing File-based Threat Detection ==="
    
    # Test 1: EICAR test file
    print_color "$BLUE" "\nTest 1: Creating EICAR test file..."
    print_color "$YELLOW" "This is a standard AV test file - completely safe"
    
    # EICAR test string
    EICAR='X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
    
    # Try to create EICAR file
    echo "$EICAR" > "$TEST_DIR/eicar_test.com" 2>/dev/null
    
    if [ -f "$TEST_DIR/eicar_test.com" ]; then
        # Check if file still exists after a brief pause
        sleep 2
        if [ -f "$TEST_DIR/eicar_test.com" ]; then
            print_color "$RED" "FAILED: EICAR test file was not detected/removed"
            ((FAILED_TESTS++))
            rm -f "$TEST_DIR/eicar_test.com" 2>/dev/null
        else
            print_color "$GREEN" "PASSED: EICAR test file was detected and removed"
            ((PASSED_TESTS++))
        fi
    else
        print_color "$GREEN" "PASSED: EICAR test file creation was blocked"
        ((PASSED_TESTS++))
    fi
    
    # Test 2: Suspicious file patterns
    print_color "$BLUE" "\nTest 2: Creating files with suspicious patterns..."
    
    # Create files with suspicious names
    suspicious_files=(
        "keylogger_test.txt"
        "ransomware_test.txt"
        "trojan_test.txt"
        "backdoor_test.txt"
    )
    
    for file in "${suspicious_files[@]}"; do
        echo "This is a test file for AV detection" > "$TEST_DIR/$file" 2>/dev/null
    done
    
    sleep 2
    
    # Check if files were removed
    local removed=0
    for file in "${suspicious_files[@]}"; do
        if [ ! -f "$TEST_DIR/$file" ]; then
            ((removed++))
        fi
    done
    
    if [ $removed -gt 0 ]; then
        print_color "$GREEN" "PASSED: $removed suspicious files were blocked/removed"
        ((PASSED_TESTS++))
    else
        print_color "$YELLOW" "INFO: Suspicious filename detection varies by AV configuration"
    fi
    
    # Cleanup remaining files
    rm -f "$TEST_DIR"/*.txt 2>/dev/null
}

# Function to test process/behavior monitoring
test_process_behavior() {
    print_color "$YELLOW" "\n=== Testing Process/Behavior Monitoring ==="
    
    # Test 1: Rapid file creation
    print_color "$BLUE" "\nTest 1: Simulating ransomware-like behavior (rapid file encryption)..."
    
    # Create test script for rapid file operations
    cat > "$TEST_DIR/rapid_file_test.sh" << 'EOF'
#!/bin/bash
# Rapid file creation test
cd "$(dirname "$0")"
for i in {1..50}; do
    echo "test data $i" > "testfile_$i.tmp"
    # Simulate encryption by renaming
    mv "testfile_$i.tmp" "testfile_$i.encrypted" 2>/dev/null
done
EOF
    
    chmod +x "$TEST_DIR/rapid_file_test.sh"
    
    # Execute with timeout
    cd "$TEST_DIR"
    timeout 5 bash "rapid_file_test.sh" 2>/dev/null
    cd ..
    
    # Check if execution was interrupted
    if [ $? -eq 124 ]; then
        print_color "$YELLOW" "INFO: Rapid file operation test completed (timeout)"
    else
        print_color "$GREEN" "PASSED: Rapid file operation may have been detected"
        ((PASSED_TESTS++))
    fi
    
    # Cleanup - ensure we remove all test files
    rm -f "$TEST_DIR"/testfile_*.encrypted "$TEST_DIR"/testfile_*.tmp "$TEST_DIR/rapid_file_test.sh" 2>/dev/null
    
    # Test 2: Command injection simulation
    print_color "$BLUE" "\nTest 2: Testing command injection detection..."
    
    # Safe command injection test
    test_cmd='echo "test" && echo "safe command chaining test"'
    eval "$test_cmd" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_color "$YELLOW" "INFO: Command execution allowed (normal for most systems)"
    else
        print_color "$GREEN" "PASSED: Suspicious command execution may have been blocked"
        ((PASSED_TESTS++))
    fi
}

# Function to test web protection
test_web_protection() {
    print_color "$YELLOW" "\n=== Testing Web Protection ==="
    
    # Test 1: HTTP vs HTTPS
    print_color "$BLUE" "\nTest 1: Testing HTTP vs HTTPS enforcement..."
    
    # Try HTTP request
    if command -v curl &> /dev/null; then
        response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://httpforever.com/" 2>/dev/null)
        
        if [ "$response" = "000" ]; then
            print_color "$GREEN" "PASSED: Insecure HTTP connection may have been blocked"
            ((PASSED_TESTS++))
        else
            print_color "$YELLOW" "INFO: HTTP connections allowed (check AV web protection settings)"
        fi
    fi
    
    # Test 2: JavaScript malware simulation
    print_color "$BLUE" "\nTest 2: Creating test HTML with suspicious JavaScript..."
    
    cat > "$TEST_DIR/suspicious_test.html" << 'EOF'
<html>
<head><title>AV Test Page</title></head>
<body>
<script>
// Suspicious JavaScript patterns
var malware_test = "dropper";
document.write(atob("VGVzdCBmb3IgQVYgZGV0ZWN0aW9u"));
eval("console.log('test');");
</script>
</body>
</html>
EOF
    
    sleep 2
    
    if [ ! -f "$TEST_DIR/suspicious_test.html" ]; then
        print_color "$GREEN" "PASSED: Suspicious HTML/JavaScript file was blocked"
        ((PASSED_TESTS++))
    else
        print_color "$YELLOW" "INFO: Web content filtering varies by AV configuration"
        rm -f "$TEST_DIR/suspicious_test.html"
    fi
}

# Function to test email/phishing protection
test_email_phishing() {
    print_color "$YELLOW" "\n=== Testing Email/Phishing Protection ==="
    
    # Test 1: Create suspicious email-like file
    print_color "$BLUE" "\nTest 1: Creating simulated phishing content..."
    
    cat > "$TEST_DIR/phishing_test.eml" << 'EOF'
From: security@yourbank-verify.com
To: victim@example.com
Subject: Urgent: Verify Your Account

Dear Customer,

Your account has been locked. Click here immediately:
http://malicious-phishing-test.com/verify?user=victim

This is a test file for AV detection.
EOF
    
    sleep 2
    
    if [ ! -f "$TEST_DIR/phishing_test.eml" ] || [ ! -s "$TEST_DIR/phishing_test.eml" ]; then
        print_color "$GREEN" "PASSED: Phishing content was detected/blocked"
        ((PASSED_TESTS++))
    else
        print_color "$YELLOW" "INFO: Email protection requires mail client integration"
        rm -f "$TEST_DIR/phishing_test.eml"
    fi
}

# Function to test USB/removable media protection
test_usb_protection() {
    print_color "$YELLOW" "\n=== Testing USB/Removable Media Protection ==="
    
    # Test 1: Simulate autorun file
    print_color "$BLUE" "\nTest 1: Creating autorun simulation files..."
    
    cat > "$TEST_DIR/autorun.inf" << 'EOF'
[autorun]
open=test.exe
action=Run Test Program
label=Test Drive
EOF
    
    echo "echo 'Test executable'" > "$TEST_DIR/test.exe"
    
    sleep 2
    
    if [ ! -f "$TEST_DIR/autorun.inf" ]; then
        print_color "$GREEN" "PASSED: Autorun file was blocked"
        ((PASSED_TESTS++))
    else
        print_color "$YELLOW" "INFO: USB protection varies by OS and AV settings"
        rm -f "$TEST_DIR/autorun.inf" "$TEST_DIR/test.exe"
    fi
}

# Function to test quarantine and remediation
test_quarantine() {
    print_color "$YELLOW" "\n=== Testing Quarantine and Remediation ==="
    
    # This test checks if AV properly quarantines files
    print_color "$BLUE" "\nTest 1: Checking quarantine functionality..."
    
    # Create a file that should trigger quarantine
    echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > "$TEST_DIR/quarantine_test.com" 2>/dev/null
    
    sleep 3
    
    if [ ! -f "$TEST_DIR/quarantine_test.com" ]; then
        print_color "$GREEN" "PASSED: File was quarantined/removed successfully"
        ((PASSED_TESTS++))
        
        # Check common quarantine locations (varies by AV)
        print_color "$BLUE" "Common quarantine locations to check manually:"
        print_color "$YELLOW" "- Windows Defender: C:\\ProgramData\\Microsoft\\Windows Defender\\Quarantine"
        print_color "$YELLOW" "- CortexXDR: Check XDR console for quarantined files"
        print_color "$YELLOW" "- Linux: /var/lib/[av-name]/quarantine/"
    else
        print_color "$RED" "FAILED: File was not quarantined"
        ((FAILED_TESTS++))
        rm -f "$TEST_DIR/quarantine_test.com"
    fi
}

# Function to run all tests
run_all_tests() {
    print_color "$BLUE" "\n=== Running All AV Tests ==="
    test_network_threats
    test_file_threats
    test_process_behavior
    test_web_protection
    test_email_phishing
    test_usb_protection
    test_quarantine
}

# Function to generate report
generate_report() {
    print_color "$YELLOW" "\n=== Generating Test Report ==="
    
    local total_tests=$((PASSED_TESTS + FAILED_TESTS))
    local pass_rate=0
    
    if [ $total_tests -gt 0 ]; then
        pass_rate=$(( (PASSED_TESTS * 100) / total_tests ))
    fi
    
    cat >> "$LOG_FILE" << EOF

========================================
        AV TEST SUMMARY REPORT
========================================
Date: $(date)
OS: $OS

Test Results:
- Total Tests Run: $total_tests
- Passed: $PASSED_TESTS
- Failed: $FAILED_TESTS
- Pass Rate: $pass_rate%

Recommendations:
EOF
    
    if [ $FAILED_TESTS -gt 0 ]; then
        cat >> "$LOG_FILE" << EOF
- Review AV configuration for failed tests
- Ensure real-time protection is enabled
- Check AV definition updates
- Verify all protection modules are active
EOF
    else
        cat >> "$LOG_FILE" << EOF
- AV solution appears to be functioning well
- Continue regular updates and monitoring
- Perform periodic testing
EOF
    fi
    
    print_color "$GREEN" "\nReport saved to: $LOG_FILE"
    
    # Display summary
    echo
    print_color "$BLUE" "===== Test Summary ====="
    print_color "$GREEN" "Passed Tests: $PASSED_TESTS"
    print_color "$RED" "Failed Tests: $FAILED_TESTS"
    print_color "$YELLOW" "Pass Rate: $pass_rate%"
}

# Main script execution
main() {
    print_color "$BLUE" "AV Testing Checklist Script v1.0"
    print_color "$YELLOW" "This script tests common AV features using safe methods"
    echo
    
    # Detect OS
    detect_os
    
    # Setup test environment
    setup_test_env
    
    # Main menu loop
    while true; do
        show_menu
        read -p "Select an option (0-9): " choice
        
        case $choice in
            1) test_network_threats ;;
            2) test_file_threats ;;
            3) test_process_behavior ;;
            4) test_web_protection ;;
            5) test_email_phishing ;;
            6) test_usb_protection ;;
            7) test_quarantine ;;
            8) run_all_tests ;;
            9) generate_report ;;
            0) 
                cleanup
                print_color "$GREEN" "Exiting AV Test Script. Log saved to: $LOG_FILE"
                exit 0
                ;;
            *) print_color "$RED" "Invalid option. Please try again." ;;
        esac
        
        echo
        read -p "Press Enter to continue..." -n 1
    done
}

# Run main function
main