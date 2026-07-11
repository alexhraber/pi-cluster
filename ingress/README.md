# Ingress (deferred)

No ingress controller is installed. The future design is two or more replicas
pinned to known Pis, with LAN reachability that remains valid when Cube is
off. It must document health checks, TLS recovery, and Pi-loss behavior.
