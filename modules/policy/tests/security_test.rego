package terraform.security

# Test data for security policy validation
test_compute_instance_without_environment_label {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_compute_instance.test",
            "type": "google_compute_instance",
            "change": {
                "after": {
                    "labels": {}
                }
            }
        }]
    }
}

test_compute_instance_with_environment_label {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "google_compute_instance.test",
            "type": "google_compute_instance",
            "change": {
                "after": {
                    "labels": {
                        "environment": "dev"
                    }
                }
            }
        }]
    }
}

test_storage_bucket_without_encryption {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_storage_bucket.test",
            "type": "google_storage_bucket",
            "change": {
                "after": {}
            }
        }]
    }
}

test_storage_bucket_with_encryption {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "google_storage_bucket.test",
            "type": "google_storage_bucket",
            "change": {
                "after": {
                    "encryption": {
                        "default_kms_key_name": "projects/test/locations/us/keyRings/test/cryptoKeys/test"
                    }
                }
            }
        }]
    }
}

test_firewall_allows_all_traffic {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_compute_firewall.test",
            "type": "google_compute_firewall",
            "change": {
                "after": {
                    "source_ranges": ["0.0.0.0/0"],
                    "direction": "INGRESS"
                }
            }
        }]
    }
}