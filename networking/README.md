# Networking contract

The initial CNI is K3s Flannel VXLAN. Pod routes and Kubernetes Service rules
already installed on each worker do not require Cube to remain powered. Do
not replace it without measuring CPU, memory, packet loss, and reconnect
behavior on Pi 3B+.

The proposed address, DNS, reservation, and ingress contract is in
[lan-plan.md](lan-plan.md). It uses `cube.lan` plus `pi-01.lan` through
`pi-04.lan`, with fixed addresses proposed for operator confirmation.

Production workload exposure is planned through redundant ingress on known
Pis. Direct host ports are diagnostic-only until that ingress is designed and
deployed. North-south traffic must use the LAN/router and Pi addresses, never
Cube as a transit dependency.
