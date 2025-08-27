package terraform.compliance

# Test data for compliance policy validation
test_iam_member_external_domain {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_project_iam_member.test",
            "type": "google_project_iam_member",
            "change": {
                "after": {
                    "member": "user:external@gmail.com"
                }
            }
        }]
    }
}

test_iam_member_corporate_domain {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "google_project_iam_member.test",
            "type": "google_project_iam_member",
            "change": {
                "after": {
                    "member": "user:employee@netskope.com"
                }
            }
        }]
    }
}

test_manual_service_account_key {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_service_account_key.test",
            "type": "google_service_account_key",
            "change": {
                "after": {}
            }
        }]
    }
}

test_sql_instance_with_public_ip {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_sql_database_instance.test",
            "type": "google_sql_database_instance",
            "change": {
                "after": {
                    "settings": [{
                        "ip_configuration": [{
                            "ipv4_enabled": true
                        }]
                    }]
                }
            }
        }]
    }
}

test_default_network_creation {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_compute_network.default",
            "type": "google_compute_network",
            "change": {
                "after": {
                    "name": "default"
                }
            }
        }]
    }
}

test_ssh_from_internet {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_compute_firewall.ssh",
            "type": "google_compute_firewall",
            "change": {
                "after": {
                    "allow": [{
                        "ports": ["22"]
                    }],
                    "source_ranges": ["0.0.0.0/0"]
                }
            }
        }]
    }
}