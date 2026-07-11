# Service mesh decision

No mesh is installed or approved for the initial cluster. See
[the evaluation and measurement gate](../docs/service-mesh.md). Linkerd and
Istio ambient remain disposable test candidates only; any future pilot must
demonstrate acceptable measured memory per Pi, identity recovery, control-plane
outage behavior, and a rehearsed rollback to this no-mesh state.
