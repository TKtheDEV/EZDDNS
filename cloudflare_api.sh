# Function to get the DNS record ID for a given FQDN and record type from Cloudflare
cf_get_record_id() {
    fqdn=$1         # Fully Qualified Domain Name
    record_type=$2  # DNS record type (e.g., A, AAAA)

    # Send a GET request to the Cloudflare API to fetch the DNS record
    api_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records?type=${record_type}&name=${fqdn}" \
        -H "Authorization: Bearer ${apiToken}" \
        -H "Content-Type: application/json")

    # Check if the curl command was successful
    if [[ $? -ne 0 ]]; then
        echo "Failed to communicate with Cloudflare API"
        return 1
    fi

    # Check if the API response indicates success
    success=$(echo "$api_response" | grep -o '"success":true')

    if [[ -z "$success" ]]; then
        echo "Failed to fetch record ID for ${fqdn} (${record_type}) from Cloudflare API"
        return 1
    fi

    # Extract the record ID from the API response
    record_id=$(echo "$api_response" | grep -oE '"id":"[^"]+"' | head -n 1 | cut -d':' -f2 | tr -d '"')
    echo "$record_id"  # Output the record ID
    return 0
}

# Function to create a new DNS record in Cloudflare
cf_create_record() {
    fqdn=$1          # Fully Qualified Domain Name
    record_type=$2   # DNS record type (e.g., A, AAAA)
    record_value=$3  # The IP address or value for the DNS record

    # Send a POST request to the Cloudflare API to create a new DNS record
    api_response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records" \
        -H "Authorization: Bearer ${apiToken}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"${record_type}\",\"name\":\"${fqdn}\",\"content\":\"${record_value}\",\"ttl\":60,\"proxied\":false}")
 
    # Check if the curl command was successful
    if [[ $? -ne 0 ]]; then
        echo "Failed to communicate with Cloudflare API"
        return 1
    fi
   
    # Check if the API response indicates success
    success=$(echo "$api_response" | grep -o '"success":true')

    if [[ -z "$success" ]]; then
        echo "Failed to create ${record_type} record for ${fqdn} via Cloudflare API."
        return 1
    else 
        echo "Created ${record_type} record for ${fqdn} with IP ${record_value}."
    fi
    return 0
}

# Function to update an existing DNS record in Cloudflare
cf_update_record() {
    fqdn=$1          # Fully Qualified Domain Name
    record_type=$2   # DNS record type (e.g., A, AAAA)
    record_value=$3  # The new IP address or value for the DNS record
    record_id=$4     # The Cloudflare ID of the record to update

    # Send a PUT request to the Cloudflare API to update the existing DNS record
    response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records/${record_id}" \
        -H "Authorization: Bearer ${apiToken}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"${record_type}\",\"name\":\"${fqdn}\",\"content\":\"${record_value}\",\"ttl\":60,\"proxied\":false}")

    # Check if the curl command was successful
    if [[ $? -ne 0 ]]; then
        echo "Failed to communicate with Cloudflare API"
        return 1
    fi

    # Check if the API response indicates success
    success=$(echo "$response" | grep -o '"success":true')

    if [[ -z "$success" ]]; then
        echo "Failed to update ${record_type} record for ${fqdn} via Cloudflare API."
        return 1
    else 
        echo "Updated ${record_type} record for ${fqdn} with IP ${record_value}."
    fi
    return 0
}

# Function to update or create a DNS record in Cloudflare
cf_update_dns_record() {
    fqdn=$1          # Fully Qualified Domain Name
    record_type=$2   # DNS record type (e.g., A, AAAA)
    record_value=$3  # The IP address or value for the DNS record

    # Get the record ID for the DNS record (if it exists)
    record_id=$(cf_get_record_id "${fqdn}" "${record_type}")

    # If no record ID is found, create a new DNS record
    if [[ -z "$record_id" ]]; then
        echo "Creating new ${record_type} record for ${fqdn} with IP ${record_value}."
        cf_create_record "${fqdn}" "${record_type}" "${record_value}"
    else
        # If a record ID is found, update the existing DNS record
        echo "Updating ${record_type} record for ${fqdn} with IP ${record_value} (CF-ID: ${record_id})."
        cf_update_record "${fqdn}" "${record_type}" "${record_value}" "${record_id}"
    fi
}
