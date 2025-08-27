#!/bin/bash

# VPN Connectivity Test Script
# This script runs on the test instance to verify VPN connectivity

set -e

# Configuration
LOG_FILE="/var/log/vpn-connectivity-test.log"
METRICS_ENDPOINT="https://monitoring.googleapis.com/v3/projects/${PROJECT_ID}/timeSeries"
TEST_TARGETS="${TEST_TARGETS:-8.8.8.8,1.1.1.1}"
ON_PREM_TARGETS="${ON_PREM_TARGETS:-}"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Install required packages
install_dependencies() {
    log "Installing dependencies..."
    apt-get update -q
    apt-get install -y curl jq traceroute mtr-tiny netcat-openbsd
}

# Test basic connectivity
test_basic_connectivity() {
    log "Testing basic connectivity..."
    
    local success=0
    local total=0
    
    IFS=',' read -ra TARGETS <<< "$TEST_TARGETS"
    for target in "${TARGETS[@]}"; do
        total=$((total + 1))
        if ping -c 3 -W 5 "$target" > /dev/null 2>&1; then
            log "✓ Ping to $target successful"
            success=$((success + 1))
        else
            log "✗ Ping to $target failed"
        fi
    done
    
    local connectivity_ratio=$(echo "scale=2; $success / $total" | bc -l)
    log "Basic connectivity ratio: $connectivity_ratio"
    
    # Send metric to Cloud Monitoring
    send_metric "vpn_basic_connectivity_ratio" "$connectivity_ratio"
}

# Test on-premises connectivity
test_onprem_connectivity() {
    if [[ -z "$ON_PREM_TARGETS" ]]; then
        log "No on-premises targets configured, skipping test"
        return
    fi
    
    log "Testing on-premises connectivity..."
    
    local success=0
    local total=0
    
    IFS=',' read -ra TARGETS <<< "$ON_PREM_TARGETS"
    for target in "${TARGETS[@]}"; do
        total=$((total + 1))
        if ping -c 3 -W 10 "$target" > /dev/null 2>&1; then
            log "✓ On-prem ping to $target successful"
            success=$((success + 1))
        else
            log "✗ On-prem ping to $target failed"
            # Perform traceroute for debugging
            log "Traceroute to $target:"
            traceroute -m 10 "$target" 2>&1 | tee -a "$LOG_FILE"
        fi
    done
    
    local onprem_ratio=$(echo "scale=2; $success / $total" | bc -l)
    log "On-premises connectivity ratio: $onprem_ratio"
    
    # Send metric to Cloud Monitoring
    send_metric "vpn_onprem_connectivity_ratio" "$onprem_ratio"
}

# Test VPN tunnel latency
test_vpn_latency() {
    if [[ -z "$ON_PREM_TARGETS" ]]; then
        log "No on-premises targets configured, skipping latency test"
        return
    fi
    
    log "Testing VPN tunnel latency..."
    
    IFS=',' read -ra TARGETS <<< "$ON_PREM_TARGETS"
    for target in "${TARGETS[@]}"; do
        local latency=$(ping -c 10 -W 5 "$target" 2>/dev/null | grep 'avg' | awk -F'/' '{print $5}' || echo "0")
        if [[ "$latency" != "0" ]]; then
            log "Latency to $target: ${latency}ms"
            send_metric "vpn_tunnel_latency_ms" "$latency" "target=$target"
        fi
    done
}

# Test DNS resolution
test_dns_resolution() {
    log "Testing DNS resolution..."
    
    local test_domains="google.com,cloudflare.com"
    local success=0
    local total=0
    
    IFS=',' read -ra DOMAINS <<< "$test_domains"
    for domain in "${DOMAINS[@]}"; do
        total=$((total + 1))
        if nslookup "$domain" > /dev/null 2>&1; then
            log "✓ DNS resolution for $domain successful"
            success=$((success + 1))
        else
            log "✗ DNS resolution for $domain failed"
        fi
    done
    
    local dns_ratio=$(echo "scale=2; $success / $total" | bc -l)
    log "DNS resolution ratio: $dns_ratio"
    
    send_metric "vpn_dns_resolution_ratio" "$dns_ratio"
}

# Test bandwidth
test_bandwidth() {
    log "Testing bandwidth..."
    
    # Simple bandwidth test using curl
    local test_url="http://speedtest.tele2.net/1MB.zip"
    local start_time=$(date +%s.%N)
    
    if curl -s -o /dev/null -w "%{speed_download}" "$test_url" > /tmp/speed_result 2>/dev/null; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        local speed_bps=$(cat /tmp/speed_result)
        local speed_mbps=$(echo "scale=2; $speed_bps / 1048576" | bc -l)
        
        log "Download speed: ${speed_mbps} Mbps"
        send_metric "vpn_bandwidth_mbps" "$speed_mbps"
    else
        log "Bandwidth test failed"
        send_metric "vpn_bandwidth_mbps" "0"
    fi
}

# Send metric to Cloud Monitoring
send_metric() {
    local metric_name="$1"
    local value="$2"
    local labels="$3"
    
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local instance_id=$(curl -s -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/instance/id")
    local zone=$(curl -s -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/instance/zone" | cut -d'/' -f4)
    
    local metric_data=$(cat <<EOF
{
  "timeSeries": [
    {
      "resource": {
        "type": "gce_instance",
        "labels": {
          "instance_id": "$instance_id",
          "zone": "$zone",
          "project_id": "$PROJECT_ID"
        }
      },
      "metric": {
        "type": "custom.googleapis.com/vpn/$metric_name",
        "labels": {
          "network": "$NETWORK",
          ${labels:+"$labels"}
        }
      },
      "points": [
        {
          "interval": {
            "endTime": "$timestamp"
          },
          "value": {
            "doubleValue": $value
          }
        }
      ]
    }
  ]
}
EOF
    )
    
    # Get access token
    local access_token=$(curl -s -H "Metadata-Flavor: Google" \
        "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token" | \
        jq -r '.access_token')
    
    # Send metric
    curl -s -X POST \
        -H "Authorization: Bearer $access_token" \
        -H "Content-Type: application/json" \
        -d "$metric_data" \
        "$METRICS_ENDPOINT" > /dev/null 2>&1 || log "Failed to send metric $metric_name"
}

# Generate test report
generate_report() {
    log "Generating connectivity test report..."
    
    local report_file="/tmp/vpn-connectivity-report.json"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    cat > "$report_file" <<EOF
{
  "timestamp": "$timestamp",
  "network": "$NETWORK",
  "region": "$REGION",
  "test_results": {
    "basic_connectivity": "$(grep 'Basic connectivity ratio' $LOG_FILE | tail -1 | awk '{print $NF}')",
    "onprem_connectivity": "$(grep 'On-premises connectivity ratio' $LOG_FILE | tail -1 | awk '{print $NF}')",
    "dns_resolution": "$(grep 'DNS resolution ratio' $LOG_FILE | tail -1 | awk '{print $NF}')",
    "bandwidth_mbps": "$(grep 'Download speed' $LOG_FILE | tail -1 | awk '{print $3}')"
  },
  "log_file": "$LOG_FILE"
}
EOF
    
    log "Report generated: $report_file"
    
    # Upload report to Cloud Storage if bucket is configured
    if [[ -n "$REPORT_BUCKET" ]]; then
        gsutil cp "$report_file" "gs://$REPORT_BUCKET/vpn-reports/$(date +%Y/%m/%d)/connectivity-report-$(date +%H%M%S).json"
        log "Report uploaded to Cloud Storage"
    fi
}

# Main execution
main() {
    log "Starting VPN connectivity test..."
    
    install_dependencies
    test_basic_connectivity
    test_onprem_connectivity
    test_vpn_latency
    test_dns_resolution
    test_bandwidth
    generate_report
    
    log "VPN connectivity test completed"
}

# Run main function
main "$@"