# Repository validation

The local and CI entrypoint is `scripts/validate-repo.sh`. Run it through the
flake development shell so local tooling matches CI:

```bash
nix flake check --no-build --no-update-lock-file
nix develop --accept-flake-config -c ./scripts/validate-repo.sh
decapod validate
```

The quality script performs these gates:

- Bash syntax and ShellCheck for every tracked repository shell script.
- Yamllint for GitHub Actions, Kubernetes, and secret declaration YAML.
- Kustomize rendering for the manifest root.
- A tracked-path guard rejecting kubeconfigs, certificates, databases, raw
  backups, runtime directories, and token-like artifacts.
- Gitleaks scanning with redacted output.

The GitHub Actions workflow runs the same flake and quality commands before
the Decapod validation gate. A failure should identify the gate and affected
path; fix the source file and rerun the same command locally.

The secret scan is compatible with encrypted sops declarations: public age
recipients and encrypted payloads may be tracked, but plaintext tokens,
private keys, kubeconfigs, certificates, databases, and raw backups must fail
review.
