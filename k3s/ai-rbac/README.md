# Zero-Trust RBAC for AI MCP Server

This directory contains the necessary Kubernetes `ServiceAccount`, `Role`, and `RoleBinding` definitions to grant the local AI MCP server the strict permissions defined in our architecture blueprint.

## Permission Scope
The `jarvis-mcp` service account has a split permission model:
1. **Full Deployment Rights:** Restricted exclusively to the `ai-sandbox` namespace. It can create Deployments, Services, ConfigMaps, Secrets, Ingress, and NetworkPolicies here.
2. **Global Read-Only Log Access:** A `ClusterRole` allows the AI to `get`, `list`, and `watch` pods, and `get` pod logs across the entire cluster. This allows it to troubleshoot the Keycloak pods, CoreDNS, or any other infrastructure component without the ability to modify them.

## Deployment

Apply the RBAC manifest to the cluster:
```bash
kubectl apply -f ai-rbac.yaml
```

## Extracting the Token for the MCP Server

The MCP Server (usually configured in LibreChat, AnythingLLM, or natively via a tool integration) requires an API token to authenticate against the k3s API server (`https://<VM-IP>:6443`).

Generate a long-lived token (e.g., 10 years) for the `jarvis-mcp` ServiceAccount:
```bash
# This outputs the JWT token string. Copy it securely.
kubectl create token jarvis-mcp -n ai-sandbox --duration=87600h
```

### Retrieving the Cluster CA Certificate
If the MCP server requires the cluster's CA certificate to verify the API server's TLS certificate, extract it with:
```bash
kubectl config view --raw -o jsonpath='{.clusters[?(@.name=="default")].cluster.certificate-authority-data}' | base64 -d
```
*(Your k3s cluster name may be `k3s` instead of `default` depending on your kubeconfig setup).*

## Revoking Access
If you ever need to revoke the AI's access or cycle the credential, simply delete and recreate the ServiceAccount:
```bash
kubectl delete serviceaccount jarvis-mcp -n ai-sandbox
# Re-apply the manifest
kubectl apply -f ai-rbac.yaml
```
