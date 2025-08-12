import subprocess

def is_cluster_policy_applied(policy_name):
    try:
        subprocess.run(
            ["kubectl", "get", "clusterpolicy", policy_name],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        return True
    except subprocess.CalledProcessError:
        return False

# Main logic
if is_cluster_policy_applied("insert-labels-topology-constraints"):
    print("ClusterPolicy is applied. Proceeding with restart...")
    rollout_restart_critical_services(critical_services)
else:
    print("ClusterPolicy 'insert-labels-topology-constraints' not found. Aborting restart.")
