# https://rmoff.net/2020/01/22/kafka-connect-and-schemas/
dnf install -y jq

kafkacat -b kafka_broker:29092 -q -u -X auto.offset.reset=earliest -G rmoff_cg_01 nfacctd_bmp | \
jq --compact-output --unbuffered \
    '. |
    {
        schema: {
            type: "struct", optional: false,
            fields: [
                { field: "seq", type: "int64", optional: true },
                { field: "timestamp", type: "float", optional: true },
                { field: "timestamp_event", type: "float", optional: true },
                { field: "timestamp_arrival", type: "float", optional: true },
                { field: "event_type", type: "string", optional: true },
                { field: "bmp_msg_type", type: "string", optional: true },
                { field: "bmp_router", type: "string", optional: true },
                { field: "bmp_router_port", type: "int32", optional: true },
                { field: "writer_id", type: "string", optional: true },
                { field: "local_ip", type: "string", optional: true },
                { field: "local_port", type: "int32", optional: true },
                { field: "peer_ip", type: "string", optional: true },
                { field: "remote_port", type: "int32", optional: true },
                { field: "peer_asn", type: "int64", optional: true },
                { field: "peer_type", type: "int32", optional: true },
                { field: "peer_type_str", type: "string", optional: true },
                { field: "is_in", type: "boolean", optional: true },
                { field: "is_filtered", type: "boolean", optional: true },
                { field: "is_loc", type: "boolean", optional: true },
                { field: "is_post", type: "boolean", optional: true },
                { field: "is_out", type: "boolean", optional: true },
                { field: "rd", type: "string", optional: true },
                { field: "bgp_id", type: "string", optional: true },
                { field: "bmp_peer_up_info_string", type: "string", optional: true },
                { field: "bmp_init_info_string", type: "string", optional: true },
                { field: "bmp_init_info_sysdescr", type: "string", optional: true },
                { field: "bmp_init_info_sysname", type: "string", optional: true },
                { field: "reason_type", type: "int32", optional: true },
                { field: "reason_str", type: "string", optional: true },
                { field: "reason_loc_code", type: "string", optional: true },
                { field: "log_type", type: "string", optional: true },
                { field: "afi", type: "int32", optional: true },
                { field: "safi", type: "int32", optional: true },
                { field: "ip_prefix", type: "string", optional: true },
                { field: "bgp_nexthop", type: "string", optional: true },
                { field: "as_path", type: "string", optional: true },
                { field: "as_path_id", type: "int32", optional: true },
                { field: "comms", type: "string", optional: true },
                { field: "ecomms", type: "string", optional: true },
                { field: "lcomms", type: "string", optional: true },
                { field: "origin", type: "string", optional: true },
                { field: "local_pref", type: "int32", optional: true },
                { field: "med", type: "int32", optional: true },
                { field: "aigp", type: "int32", optional: true },
                { field: "psid_li", type: "int32", optional: true },
                { field: "label", type: "string", optional: true },
                { field: "peer_tcp_port", type: "int32", optional: true },
                { field: "counter_type", type: "int32", optional: true },
                { field: "counter_type_str", type: "string", optional: true },
                { field: "counter_value", type: "int64", optional: true },
                { field: "bmp_term_info_reason", type: "string", optional: true }
            ]
        },
        payload: {
            seq: .seq,
            timestamp: .timestamp,
            timestamp_event: .timestamp_event,
            timestamp_arrival: .timestamp_arrival,
            event_type: .event_type,
            bmp_msg_type: .bmp_msg_type,
            bmp_router: .bmp_router,
            bmp_router_port: .bmp_router_port,
            writer_id: .writer_id,
            local_ip: .local_ip,
            local_port: .local_port,
            peer_ip: .peer_ip,
            remote_port: .remote_port,
            peer_asn: .peer_asn,
            peer_type: .peer_type,
            peer_type_str: .peer_type_str,
            is_in: .is_in,
            is_filtered: .is_filtered,
            is_loc: .is_loc,
            is_post: .is_post,
            is_out: .is_out,
            rd: .rd,
            bgp_id: .bgp_id,
            bmp_peer_up_info_string: .bmp_peer_up_info_string,
            bmp_init_info_string: .bmp_init_info_string,
            bmp_init_info_sysdescr: .bmp_init_info_sysdescr,
            bmp_init_info_sysname: .bmp_init_info_sysname,
            reason_type: .reason_type,
            reason_str: .reason_str,
            reason_loc_code: .reason_loc_code,
            log_type: .log_type,
            afi: .afi,
            safi: .safi,
            ip_prefix: .ip_prefix,
            bgp_nexthop: .bgp_nexthop,
            as_path: .as_path,
            as_path_id: .as_path_id,
            comms: .comms,
            ecomms: .ecomms,
            lcomms: .lcomms,
            origin: .origin,
            local_pref: .local_pref,
            med: .med,
            aigp: .aigp,
            psid_li: .psid_li,
            label: .label,
            peer_tcp_port: .peer_tcp_port,
            counter_type: .counter_type,
            counter_type_str: .counter_type_str,
            counter_value: .counter_value,
            bmp_term_info_reason: .bmp_term_info_reason
        }
    }' | \
kafkacat -b kafka_broker:29092 -t nfacctd_bmp-with-schema -P -u