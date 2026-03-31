# BavsworldAI: Agentic Workloads & Applications 🧠

This repository contains the application-layer deployments for the generative AI and orchestration workloads. 

**Infrastructure Dependency**: These applications are designed to be deployed on top of the `k3slab` infrastructure repository, which provides the underlying Kubernetes compute, Istio Service Mesh, Metallb LoadBalancing, and Cert-Manager Let's Encrypt certificates.

## 1. Deployed Workloads

### LibreChat (The AI unified front-end)
LibreChat provides a unified web interface for communicating with various local (Ollama) and remote (OpenAI, Anthropic) language models.

*   **URL**: `https://chat.bavsworld.com`
*   **Routing**: Handled by the `k3slab` Istio Ingress Gateway (`192.168.100.160`), which terminates TLS and proxies traffic to the internally clustered LibreChat service.
*   **Database Backend**: MongoDB (State, user accounts, and conversations)
*   **Search Backend**: MeiliSearch (Vector-based chat history searching)

## 2. Directory Structure

```text
bavsworldai/
├── k3s/
│   ├── ai-rbac/          # Role-based access control policies for AI namespaces
│   ├── ollama-bridge/    # Bridging configurations for local LLM inference
│   └── librechat/        # Helm charts and manifests for the LibreChat deployment
└── README.md
```

## 3. Deployment Workflow

Unlike the base cluster (`k3slab`) which is deployed via Ansible, the applications in this repository are intended to be deployed via GitOps (e.g., ArgoCD) or standard Helm applying, treating the `k3slab` foundation as an immutable infrastructure layer.
