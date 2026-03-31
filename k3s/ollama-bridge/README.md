# Ollama Host Bridge — k3s to Windows Host

This directory contains the manifests that create a secure, DNS-resolvable bridge from the `ai-sandbox` namespace to the Windows bare-metal host's Ollama API.

## Network Topology

| Host | IP | Interface |
|------|----|-----------|
| Windows bare-metal (Ollama) | `<HOST-IP>` | `vEthernet (PrimarySwitch)` |
| k3s Hyper-V VM | `<VM-IP>` | Hyper-V guest NIC |
| Shared subnet | `<LAN-SUBNET>` | Same L2 broadcast domain |

## Files

| File | Purpose |
|------|---------|
| `ollama-endpoint.yaml` | Headless `Service` + `EndpointSlice` pointing at host IP `<VM-IP>:11434` |
| `ollama-networkpolicy.yaml` | Zero-trust `NetworkPolicy` restricting Ollama access to labeled pods in `ai-sandbox` only |

## How It Works

```
[Pod in ai-sandbox]  (running in Hyper-V VM @ <VM-IP>)
  label: ollama-client=true
        │
        │  DNS: ollama-host.ai-sandbox.svc.cluster.local:11434
        ▼
[Headless Service: ollama-host]
        │
        ▼
[EndpointSlice]  →  <HOST-IP>:11434  →  [Windows Host / Ollama / RTX 5090]
                    (vEthernet PrimarySwitch)
```

## 1. Windows Host Setup (Bare-Metal)

Before deploying the k3s manifests, the Windows host (RTX 5090) must be configured to run Ollama and accept inbound connections from the k3s network.

### A. Install Ollama & Pull Models
Open an **Administrator PowerShell** prompt:
```powershell
# Install Ollama using Chocolatey
choco install ollama -y

# After installation completes, pull your primary models
# (You may need to close and reopen PowerShell if 'ollama' is not in PATH yet)
ollama pull qwen2.5-coder:32b
```
*(Note: Whisper and XTTSv2 are often run via Docker or Python venvs rather than native Ollama, but any models you plan to serve via the Ollama API should be pulled here).*

### B. Bind Ollama to the Network
By default, Windows Ollama only listens on `127.0.0.1`. You must expose it to the Hyper-V virtual switch.
In an **Administrator PowerShell** prompt:
```powershell
# Set the system-wide environment variable
[System.Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0", "Machine")

# Restart the Ollama process
Stop-Process -Name "ollama" -Force -ErrorAction SilentlyContinue
Start-Process "ollama" -ArgumentList "serve"
```
*(Note: If Ollama automatically started in your system tray, right-click it, click "Quit Ollama", and then run `ollama serve` or relaunch it from the Start menu so it picks up the new environment variable).*

### C. Zero-Trust Windows Firewall
Still in the **Administrator PowerShell** prompt, lock down port 11434 so *only* the k3s ecosystem can reach your GPU:
```powershell
# Allow inbound Ollama traffic only from the k3s pod CIDR and VM IP
New-NetFirewallRule -DisplayName "Ollama - k3s ai-sandbox" `
  -Direction Inbound -Protocol TCP -LocalPort 11434 `
  -RemoteAddress "10.42.0.0/16","<VM-IP>" `
  -Action Allow

# Block all other inbound Ollama traffic
New-NetFirewallRule -DisplayName "Ollama - Deny All Other" `
  -Direction Inbound -Protocol TCP -LocalPort 11434 `
  -Action Block
```

## 2. k3s Cluster Prerequisites

**CNI with NetworkPolicy enforcement.** Vanilla Flannel does NOT enforce policies. You must be running one of:
- **Flannel + kube-router** (most common in k3s setups)
- **Calico** (recommended if you need GlobalNetworkPolicy later)
- **Cilium** (best for eBPF-level enforcement)

Verify with: `kubectl get pods -n kube-system | grep -E 'calico|cilium|kube-router'`

## Deployment

```bash
# Create namespace if not already present
kubectl create namespace ai-sandbox --dry-run=client -o yaml | kubectl apply -f -

# Apply the bridge manifests
kubectl apply -f ollama-endpoint.yaml
kubectl apply -f ollama-networkpolicy.yaml

# Verify endpoint is resolved correctly
kubectl run -n ai-sandbox debug-curl \
  --image=curlimages/curl:latest \
  --labels="ollama-client=true" \
  --restart=Never --rm -it \
  -- curl -s http://ollama-host.ai-sandbox.svc.cluster.local:11434/api/tags
```

## Labeling Your Workloads

Any pod that needs to reach Ollama must carry the label `ollama-client: "true"`. Example Deployment snippet:

```yaml
spec:
  template:
    metadata:
      labels:
        ollama-client: "true"
```

Workloads without this label will have their egress to `<VM-IP>:11434` silently dropped by the NetworkPolicy.

## Security Notes

- `default-deny-ingress` in `ai-sandbox` means you must explicitly allow any inter-pod communication you need.
- The `deny-ollama-egress-from-kube-system` policy should be replicated for every namespace that should not reach the GPU (monitoring, librechat namespace, etc.).
- Long-term, migrate `deny-*` policies to **Calico GlobalNetworkPolicy** for cluster-wide enforcement without per-namespace boilerplate.
