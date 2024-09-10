#!/bin/bash

# Source configuration and Cloudflare API functions
source ezddns.conf
source cloudflare_api.sh

# Initialize variables for IP addresses and prefix
v4=""
v4new=""
v6=""
v6new=""
prefix=""

# Calculate prefix count based on the prefix length
if [[ ${prefixLength} == 64 ]]; then
    prefixCount=$(( (prefixLength / 4) + 3 ))
else
    prefixCount=$(( (prefixLength / 4) + 2 ))
fi

expand_ipv6() {
    local raw_v6=$1
    local raw_pre="${raw_v6%%::*}"
    local raw_suf="${raw_v6##*::}"
    local pre_blocks=$(grep -o ":" <<< "$raw_pre" | wc -l)
    local suf_blocks=$(grep -o ":" <<< "$raw_suf" | wc -l)
    local fill_blocks=$((8 - pre_blocks - suf_blocks - 1))

    proc_addr="${raw_pre}$(for ((i=0; i<$fill_blocks; i++)); do echo -n ":0000"; done):${raw_suf}"
    echo $proc_addr | awk -F: '{ for (i=1; i<=NF; i++) printf("%s%s", sprintf("%04x", "0x"$i), (i<NF)?":":""); }'
}

# Function to parse and update custom DNS records
parse_records() {
    echo "$customRecords" | while IFS= read -r line; do
        # Extract FQDN, record type, and suffix from each line
        record_fqdn=$(echo "$line" | cut -d',' -f1)
        record_type=$(echo "$line" | cut -d',' -f2)
        suffix=$(echo "$line" | cut -d',' -f3)
        
        # Determine the record value based on type (AAAA for IPv6, A for IPv4)
        if [[ "${record_type}" == "AAAA" ]]; then
            if [[ -n "${suffix}" ]]; then
                record_value="${prefix}${suffix}"  # Use prefix + suffix for IPv6
            else
                record_value="${v6}"  # Use the full IPv6 address if no suffix
            fi
        else
            record_value="${v4}"  # Use the IPv4 address
        fi

        # Update the DNS record with the determined value
        cf_update_dns_record "${record_fqdn}" "${record_type}" "${record_value}"
    done
}

# Main loop to continuously check and update IP addresses
while true; do
    # Get the current IPv6 address
    getv6=$(curl -s -6 https://one.one.one.one/cdn-cgi/trace | grep 'ip=' | cut -d'=' -f2)
    if [[ "${getv6}" == *:*:*:*:*:*:*:* && "${legacyMode}" != true ]]; then
        v6ext=$(expand_ipv6 "$getv6")
        v6new="${v6ext:0:38}"
        prefix="${v6new:0:${prefixCount}}"  # Extract the prefix from the IPv6 address
    else
        v6new="Unavailable"
        prefix="Unavailable"
    fi

    # Get the current IPv4 address
    getv4=$(curl -s -4 https://one.one.one.one/cdn-cgi/trace | grep 'ip=' | cut -d'=' -f2)
    if [[ "${getv4}" == *.*.*.* && "${v4Enabled}" == true ]]; then
        v4new="${getv4}"
    else
        v4new="Unavailable"
    fi

    # Check if the IP addresses have changed
    if [[ "${v6new}" != "${v6}" || "${v4new}" != "${v4}" ]]; then
        v6="${v6new}"
        v4="${v4new}"
        echo "Your new public IP config: Prefix: ${prefix} IPv6: ${v6} IPv4: ${v4}"

        # Update the main DNS records if `hostfqdn` is set
        if [[ -n "${hostfqdn}" ]]; then
            if [[ "${legacyMode}" == false ]]; then
                cf_update_dns_record "${hostfqdn}" "AAAA" "${v6}"  # Update the AAAA record for IPv6
            fi

            if [[ ${v4Enabled} == true ]]; then
                cf_update_dns_record "${hostfqdn}" "A" "${v4}"  # Update the A record for IPv4
            fi
        fi

        # Parse and update custom DNS records if enabled
        if [[ ${customEnabled} = true ]]; then
            parse_records
        fi
    else
        echo "IPs haven't changed since the last update"
    fi

    # Wait for the refresh interval (converted to minutes) before checking again
    echo "Waiting $((refresh / 60)) minutes until the next update"
    sleep "${refresh}"
done
# (C) GitHub\TKtheDEV