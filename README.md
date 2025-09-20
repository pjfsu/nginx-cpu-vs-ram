# Comparing Nginx servers with different resources (CPU and RAM)

The goal of this experiment is to understand how allocating more **RAM** versus more **CPU** affects the performance of a simple Nginx HTTP server.  
We deploy Nginx pods with different resource requests/limits and benchmark them with `ab` (ApacheBench).

## Test environment

These benchmarks were executed on a local laptop:

- CPU: Intel(R) Core(TM) i5-5200U CPU @ 2.20GHz
- RAM: 11Gi
- OS: Red Hat Enterprise Linux 10.0 (Coughlan)
- Kernel: 6.12.0-55.33.1.el10_0.x86_64

## Requirements

To reproduce the tests you need:

- Podman installed (I used version 5.4.0)
- Nginx image: `docker.io/library/nginx:latest`
- ApacheBench available (I used `httpd:alpine` as the tester container, which provides `ab`)
- The provided YAML manifests and helper scripts

## Manifests (equal CPUs and different RAM)

### Nginx with low RAM (`low-ram.yaml`)
```yaml
...
resources:
  requests:
    cpu: "1"        # 1 CPU core
    memory: "1Gi"   # 1 GB RAM
  limits:
    cpu: "1"        # 1 CPU core
    memory: "1Gi"   # 1 GB RAM
```

### Nginx with medium RAM (`medium-ram.yaml`)
```yaml
...
resources:
  requests:
    cpu: "1"        # 1 CPU core
    memory: "2Gi"   # 2 GB RAM
  limits:
    cpu: "1"        # 1 CPU core
    memory: "2Gi"   # 2 GB RAM
```

### Nginx with high RAM (`high-ram.yaml`)
```yaml
...
resources:
  requests:
    cpu: "1"        # 1 CPU core
    memory: "4Gi"   # 4 GB RAM
  limits:
    cpu: "1"        # 1 CPU core
    memory: "4Gi"   # 4 GB RAM
```

## RAM test results (`ram.log`)

```
low-ram      6683.04 requests/sec	  14.963 ms average response time	  19 ms 95th percentile response time
medium-ram      6289.94 requests/sec	  15.898 ms average response time	  21 ms 95th percentile response time
high-ram      6877.00 requests/sec	  14.541 ms average response time	  20 ms 95th percentile response time
```
> ab -n 5000 -c 1000 http://\<pod-name\>:80/

**Observation:**  
Increasing memory from 1 GiB -> 2GiB -> 4 GiB does **not** significantly improve throughput or latency.  
Nginx serving small static responses is not memory‑bound; extra RAM remains unused unless caching or large buffers are configured.

## Manifests (different CPUs and equal RAM)

### Nginx with low CPU (`low-cpu.yaml`)
```yaml
...
resources:
  requests:
    cpu: "1"        # 1 CPU core
    memory: "1Gi"   # 1 GB RAM
  limits:
    cpu: "1"        # 1 CPU core
    memory: "1Gi"   # 1 GB RAM
```

### Nginx with medium CPU (`medium-cpu.yaml`)
```yaml
...
resources:
  requests:
    cpu: "2"        # 2 CPU cores
    memory: "1Gi"   # 1 GB RAM
  limits:
    cpu: "2"        # 2 CPU cores
    memory: "1Gi"   # 1 GB RAM
```

### Nginx with high CPU (`high-cpu.yaml`)
```yaml
...
resources:
  requests:
    cpu: "4"        # 4 CPU cores
    memory: "1Gi"   # 1 GB RAM
  limits:
    cpu: "4"        # 4 CPU cores
    memory: "1Gi"   # 1 GB RAM
```

## CPU test results (`cpu.log`)

```
low-cpu      6239.97 requests/sec	  16.026 ms average response time	  21 ms 95th percentile response time
medium-cpu      6173.38 requests/sec	  16.199 ms average response time	  21 ms 95th percentile response time
high-cpu      8180.71 requests/sec	  12.224 ms average response time	  14 ms 95th percentile response time
```
> ab -n 5000 -c 1000 http://\<pod-name\>:80/

**Observation:**  
Allocating more CPU cores does improve performance.  
The 4‑core pod handled more requests/sec and reduced average latency compared to the 1‑core pod.  
Scaling is not perfectly linear (due to benchmarking tool limits, network stack, and Nginx worker defaults), but the trend is clear: **CPU matters more than RAM**.

> Nginx worker defaults: by default Nginx may not spawn as many workers as there are cores, so extra cores aren’t fully used unless tuned.
> 
> Benchmarking tool bottleneck: ApacheBench (ab) itself can become the bottleneck when driving very high concurrency, especially from a single client process.
> 
> Network stack and kernel limits: TCP connection handling, socket buffers, and system limits can cap throughput before CPU is saturated.

## Summary

| Target      | CPU Cores | RAM  | Connections | Total Requests | Requests/sec | Avg Response (ms) | 95th Percentile (ms) |
|-------------|-----------|------|-------------|----------------|--------------|-------------------|----------------------|
| low-ram     | 1         | 1Gi  | 1000        | 5000           | 6683.04      | 14.96             | 19                   |
| medium-ram  | 1         | 2Gi  | 1000        | 5000           | 6289.94      | 15.90             | 21                   |
| high-ram    | 1         | 4Gi  | 1000        | 5000           | 6877.00      | 14.54             | 20                   |
| low-cpu     | 1         | 1Gi  | 1000        | 5000           | 6239.97      | 16.03             | 21                   |
| medium-cpu  | 2         | 1Gi  | 1000        | 5000           | 6173.38      | 16.20             | 21                   |
| high-cpu    | 4         | 1Gi  | 1000        | 5000           | 8180.71      | 12.22             | 14                   |

> Benchmark parameters: **5000 requests**, **1000 concurrent connections**, tested with ApacheBench (`ab`).

## Conclusion

- **More RAM**: No meaningful impact on Nginx throughput or latency for simple HTTP workloads.  
- **More CPU**: Directly improves request handling capacity and reduces response times.  
- **Implication**: For lightweight HTTP servers like Nginx, prioritize **CPU allocation** over RAM unless you need caching, buffering, or large file serving.

> Ty for reading this repo!
>
> Gracias por leer este repo!
>
> Moitas por ler iste repo!
