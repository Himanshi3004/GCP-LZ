package terraform.security.enhanced

import rego.v1

# Test cases for enhanced security policies

# Test security classification label requirement
test_security_classification_required if {
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

test_security_classification_present if {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "google_compute_instance.test",
            "type": "google_compute_instance",
            "change": {
                "after": {
                    "labels": {
                        "security_classification": "confidential"
                    }
                }
            }
        }]
    }
}

# Test CMEK requirement for storage buckets
test_storage_bucket_cmek_required if {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_storage_bucket.test",
            "type": "google_storage_bucket",
            "change": {
                "after": {
                    "encryption": [{}]
                }
            }
        }]
    }
}

test_storage_bucket_cmek_present if {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "google_storage_bucket.test",
            "type": "google_storage_bucket",
            "change": {
                "after": {
                    "encryption": [{
                        "default_kms_key_name": "projects/test/locations/us/keyRings/test/cryptoKeys/test"
                    }]
                }
            }
        }]
    }
}

# Test GKE private cluster requirement
test_gke_private_cluster_required if {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_container_cluster.test",
            "type": "google_container_cluster",
            "change": {
                "after": {
                    "private_cluster_config": [{
                        "enable_private_nodes": false
                    }]
                }
            }
        }]
    }
}

test_gke_private_cluster_enabled if {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "google_container_cluster.test",
            "type": "google_container_cluster",
            "change": {
                "after": {
                    "private_cluster_config": [{
                        "enable_private_nodes": true
                    }],
                    "network_policy": [{
                        "enabled": true
                    }],
                    "binary_authorization": [{
                        "enabled": true
                    }]
                }
            }
        }]
    }
}

# Test OS Login requirement
test_compute_oslogin_required if {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_compute_instance.test",
            "type": "google_compute_instance",
            "change": {
                "after": {
                    "metadata": {},
                    "labels": {
                        "security_classification": "confidential"
                    }
                }
            }
        }]
    }
}

test_compute_oslogin_enabled if {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "google_compute_instance.test",
            "type": "google_compute_instance",
            "change": {
                "after": {
                    "metadata": {
                        "enable-oslogin": "TRUE"
                    },
                    "labels": {
                        "security_classification": "confidential"
                    },
                    "shielded_instance_config": [{
                        "enable_secure_boot": true
                    }]
                }
            }
        }]
    }
}

# Test IAM conditions for sensitive roles
test_sensitive_role_condition_required if {
    deny[_] with input as {
        "resource_changes": [{
            "address": "google_project_iam_member.test",
            "type": "google_project_iam_member",
            "change": {
                "after": {
                    "role": "roles/owner",
                    "member": "user:test@netskope.com"
                }
            }
        }]
    }
}

test_sensitive_role_condition_present if {
    count(deny) == 0 with input as {
        "resource_changes": [{
            "address": "google_project_iam_member.test",
            "type": "google_project_iam_member",
            "change": {
                "after": {
                    "role": "roles/owner",
                    "member": "user:test@netskope.com",
                    "condition": {
                        "title": "Time-based access",
                        "expression": "request.time.getHours() >= 9 && request.time.getHours() <= 17"
                    }
                }
            }
        }]
    }
}