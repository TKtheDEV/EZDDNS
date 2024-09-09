cf_get_record_id() {
    fqdn=$1
    record_type=$2
    api_response=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records?type=${record_type}&name=${fqdn}" \
        -H "Authorization: Bearer ${apiToken}" \
        -H "Content-Type: application/json")

    if [[ $? -ne 0 ]]; then
        echo "Failed to communicate with Cloudflare API"
        return 1
    fi

    success=$(echo "$api_response" | grep -o '"success":true')

    if [[ -z "$success" ]]; then
        echo "Failed to fetch record ID for ${fqdn} (${record_type}) from Cloudflare API"
        return 1
    fi

    record_id=$(echo "$api_response" | grep -oE '"id":"[^"]+"' | head -n 1 | cut -d':' -f2 | tr -d '"')
    echo "$record_id"
    return 0
}

cf_create_record(){
    fqdn=$1
    record_type=$2
    record_value=$3
    api_response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records" \
        -H "Authorization: Bearer ${apiToken}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"${record_type}\",\"name\":\"${fqdn}\",\"content\":\"${record_value}\",\"ttl\":60,\"proxied\":false}")
    
    success=$(echo "$api_response" | grep -o '"success":true')

    if [[ -z "$success" ]]; then
        echo "Failed to create ${record_type} record for ${fqdn} via Cloudflare API."
        return 1
    else 
        echo "Created ${record_type} record for ${fqdn} with IP ${record_value}."
    fi
    return 0
}

cf_update_record() {
    fqdn=$1
    record_type=$2
    record_value=$3
    record_id=$4
    response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${zoneId}/dns_records/${record_id}" \
        -H "Authorization: Bearer ${apiToken}" \
        -H "Content-Type: application/json" \
        --data "{\"type\":\"${record_type}\",\"name\":\"${fqdn}\",\"content\":\"${record_value}\",\"ttl\":60,\"proxied\":false}")

    success=$(echo "$api_response" | grep -o '"success":true')

    if [[ -z "$success" ]]; then
        echo "Failed to Update ${record_type} record for ${fqdn} via Cloudflare API."
        return 1
    else 
        echo "Updated ${record_type} record for ${fqdn} with IP ${record_value}."
    fi
    return 0
}

cf_update_dns_record() {
    fqdn=$1
    record_type=$2
    record_value=$3
    record_id=$(cf_get_record_id "${fqdn}" "${record_type}")    
    if [[ -z "$record_id" ]]; then
        echo "Creating new ${record_type} record for ${fqdn} with IP ${record_value}."
        cf_create_record "${fqdn}" "${record_type}" "${record_value}"
    else
        echo "Updating ${record_type} record for ${fqdn} with IP ${record_value} (CF-ID: ${record_id})."
        cf_update_record "${fqdn}" "${record_type}" "${record_value}" "${record_id}"
    fi

}