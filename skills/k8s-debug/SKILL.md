---
name: k8s-debug
description: Quick Kubernetes debugging — check pod status, events, logs, and describe for a resource. One command to triage.
allowed-tools: Bash, Read, Grep
argument-hint: "<resource> [namespace] [--context ctx] [--logs] [--events] [--all]"
---

Quickly triage a Kubernetes resource by gathering status, events, logs, and description in one pass.

## Process

Parse `$ARGUMENTS`:
- First arg: resource identifier (e.g., `pod/my-app`, `deploy/nginx`, `svc/api`, or just `my-app` which defaults to pod)
- Second arg (optional): namespace (default: use current context's namespace)
- `--context <ctx>`: kubectl context to use
- `--logs`: include container logs (last 50 lines per container)
- `--events`: include namespace events filtered to this resource
- `--all`: equivalent to `--logs --events` (default behavior if no flags given)

If no flags are specified, default to `--all` (show everything).

Build the kubectl context flag: `CTX=""` or `CTX="--context <ctx>"` if specified.

1. **Identify the resource**:
   ```bash
   # If no resource type prefix, search for it
   kubectl get pod,deploy,svc,sts,ds,job -n <namespace> $CTX 2>/dev/null | grep -i <name>
   ```
   If ambiguous, list matches and ask for clarification.

2. **Get status overview**:
   ```bash
   kubectl get <resource> -n <namespace> $CTX -o wide
   ```

3. **Describe the resource** (always):
   ```bash
   kubectl describe <resource> -n <namespace> $CTX
   ```
   Extract and highlight:
   - **Status/Phase**: Running, Pending, CrashLoopBackOff, etc.
   - **Conditions**: Ready, Scheduled, ContainersReady, etc.
   - **Recent Events**: from the describe output (last 10)
   - **Restart count**: if applicable
   - **Node**: which node it's on
   - **Images**: container image versions

4. **Logs** (if `--logs` or `--all`):
   ```bash
   # Current logs
   kubectl logs <resource> -n <namespace> $CTX --all-containers --tail=50
   # If pod is in CrashLoopBackOff, also get previous logs
   kubectl logs <resource> -n <namespace> $CTX --all-containers --previous --tail=30 2>/dev/null || true
   ```

5. **Namespace events** (if `--events` or `--all`):
   ```bash
   kubectl events -n <namespace> $CTX --for <resource> 2>/dev/null || \
     kubectl get events -n <namespace> $CTX --sort-by='.lastTimestamp' | tail -20
   ```

6. **Diagnosis**:
   Based on the gathered information, provide:
   - **Status**: one-line summary (e.g., "Pod is in CrashLoopBackOff due to OOMKilled")
   - **Root cause**: best guess based on events, logs, and conditions
   - **Suggested actions**: concrete next steps (e.g., "Increase memory limit from 128Mi to 256Mi in values.yaml")

## Output Format

```
## <resource> in <namespace>

**Status:** <one-line summary>
**Node:** <node> | **Restarts:** <count> | **Age:** <age>
**Images:** <image:tag list>

### Conditions
<table or list of conditions and their status>

### Recent Events
<last 5-10 events, most recent first>

### Logs (last 50 lines)
<logs, truncated if very long>

### Diagnosis
**Root cause:** <best guess>
**Suggested actions:**
1. <action>
2. <action>
```

## Notes

- If the resource doesn't exist, search broadly and suggest similar resources.
- For deployments/statefulsets, also check the individual pods underneath.
- If multiple pods match (e.g., from a deployment), show the unhealthiest pod first.
- Never run `kubectl delete`, `kubectl edit`, or any mutating command. This skill is read-only.
