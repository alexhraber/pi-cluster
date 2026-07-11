# Ingress (deferred)

No ingress controller is installed. The selected future design is documented
in [design.md](design.md): two Traefik replicas pinned to `pi-01` and `pi-02`,
fixed NodePorts, and LAN DNS answers for both Pi addresses. The design includes
resource gates, health checks, TLS recovery, Cube-off behavior, and Pi-loss
handling. Installation remains a separate approved change.
