#!/bin/sh
source ezddns.conf
source cloudflare_api.sh

#variables
v4=""
v4new=""
v6=""
v6new=""
prefix=""

if [[ ${prefixLength} == 64 ]]; then
    prefixCount=$(( (prefixLength / 4) + 3 ))
else
    prefixCount=$(( (prefixLength / 4) + 2 ))
fi



parse_records() {
    echo "$customRecords" | while IFS= read -r line; do
        record_fqdn=$(echo "$line" | cut -d',' -f1)
        record_type=$(echo "$line" | cut -d',' -f2)
        suffix=$(echo "$line" | cut -d',' -f3)
        if [[ "${record_type}" == "AAAA" ]]; then
            if [[ -n "${suffix}" ]]; then
                record_value="${prefix}${suffix}"
            else
                record_value="${v6}"
            fi
        else
            record_value="${v4}"
        fi

        cf_update_dns_record "${record_fqdn}" "${record_type}" "${record_value}"
    done
}

while true; do

    getv6=$(curl -s -6 ifconfig.co)
    if [[ "${getv6}" == *:*:*:*:*:*:*:* && "${legacy}" != true ]]; then
        v6new="${getv6:0:38}"
        prefix="${v6new:0:${prefixCount}}"
    else
        v6new="Unavailable"
        prefix="Unavailable"
    fi

    getv4=$(curl -s -4 ifconfig.co)
    if [[ "${getv4}" == *.*.*.* && "${v4Enabled}" == true ]]; then
        v4new="${getv4}"
    else
        v4new="Unavailable"
    fi

    if [[ "${v6new}" != "${v6}" || "${v4new}" != "${v4}" ]]; then
        v6="${v6new}"
        v4="${v4new}"
        echo "Your new public IP config: Prefix: ${prefix} IPv6: ${v6} IPv4: ${v4}"

        if [[ -n "${hostfqdn}" ]]; then
            if [[ "${legacyMode}" == false ]]; then
                cf_update_dns_record "${hostfqdn}" "AAAA" "${v6}"
            fi

            if [[ ${v4Enabled} == true ]]; then
                cf_update_dns_record "${hostfqdn}" "A" "${v4}"
            fi
        fi

        if [[ ${customEnabled} = true ]]; then
            parse_records
        fi
    else
        echo "IPs haven't changed since the last update"
    fi
    echo "Waiting $((refresh / 60)) minutes until the next update"
    sleep "${refresh}"
done
