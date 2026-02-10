#!/bin/bash
# Helper script to run a single property test method
# Usage: ./run_single_test.sh <test_file> <test_method>
# Example: ./run_single_test.sh test_door_placement_properties.gd property_27_connection_point_calculation_integration

if [ $# -lt 2 ]; then
    echo "Usage: $0 <test_file> <test_method>"
    echo "Example: $0 test_door_placement_properties.gd property_27_connection_point_calculation_integration"
    echo "Note: test_method should NOT include 'test_' prefix"
    exit 1
fi

TEST_FILE=$1
TEST_METHOD=$2

echo "Running test: test_$TEST_METHOD from $TEST_FILE"
echo "================================================"

# Run only the specified test method from the specified file
# Filter output to show only relevant test results
godot --headless --script addons/gut/gut_cmdln.gd \
    -gdir=tests/property \
    -ginclude_subdirs \
    -gprefix="$TEST_FILE" \
    -gtest="$TEST_METHOD" \
    2>&1 | tail -50
