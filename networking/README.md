# Networking contract

The initial CNI is K3s Flannel VXLAN. Pod routes and Kubernetes Service rules
already installed on each worker do not require Cube to remain powered. Do
not replace it without measuring CPU, memory, packet loss, and reconnect
behavior on Pi 3B+.

Reserve fixed LAN addresses for Cube and all Pis. Selected workloads may later
be exposed through redundant ingress on known Pis or a documented host port.
North-south traffic must use the LAN/router and Pi addresses, never Cube as a
transit dependency. LAN DNS should provide `cube.lan` and Pi names.
