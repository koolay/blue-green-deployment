# blue-green deployment with nginx ingress and istio

reviews 微服务有 3 个版本：
https://raw.githubusercontent.com/istio/istio/release-1.17/samples/bookinfo/platform/kube/bookinfo.yaml;

- v1 版本不会调用ratings 服务
- v2 版本会调用 ratings 服务，并使用 1 到 5 个黑色星形图标来显示评分信息。
- v3 版本会调用 ratings 服务，并使用 1 到 5 个红色星形图标来显示评分信息。

## Install

- Install istio(without gateway)

```bash
# https://istio.io/latest/docs/setup/install/helm/

kubectl create namespace istio-system;
helm repo add istio https://istio-release.storage.googleapis.com/charts;
helm repo update;
helm install istio-base istio/base -n istio-system;
helm install istiod istio/istiod -n istio-system;
helm status istiod -n istio-system;

```

- Inject istio sidercar

```bash 
kubectl create namespace bookinfo;
kubectl create namespace nginx-ingress;

kubectl label namespace bookinfo istio-injection=enabled;
kubectl label nginx-ingress bookinfo istio-injection=enabled;

kubectl get namespace -L istio-injection;

```

- Install nginx ingress(from kubernetes's org)

```bash

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade -i --namespace nginx-ingress nginx-ingress ingress-nginx/ingress-nginx -f ./ingress-nginx.values.yaml

```

- Make tls local

```bash
# https://github.com/FiloSottile/mkcert
# Install the local CA in the system trust store.
mkcert -install
mkcert "*.local.dev" 127.0.0.1 ::1
```

- Install bookinfo microservices

```bash
kubectl -n bookinfo apply -f ./bookinfo;
kubectl -n bookinfo apply -f ./vservice;
# create tls secret
kubectl -n bookinfo create secret tls tls-secret-local --key ~/.local/share/mkcert/_wildcard.local.dev+2-key.pem \
        --cert ~/.local/share/mkcert/_wildcard.local.dev+2.pem
```

## Test

Open `https://bookinfo.local.dev` and `https://bookinfo.staging.local.dev`

## How nginx ingress work with istio

### ingress controller

```yaml
controller:
  podAnnotations:
    sidecar.istio.io/inject: 'true'
    traffic.sidecar.istio.io/includeInboundPorts: ""
    traffic.sidecar.istio.io/excludeInboundPorts: "80,443"
```

### ingress resource

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/service-upstream: "true"
    nginx.ingress.kubernetes.io/upstream-vhost: productpage.bookinfo.svc.cluster.local
    nginx.ingress.kubernetes.io/configuration-snippet: |
          more_set_input_headers 'env: staging';
  name: bookinfo-staging
spec:
  ingressClassName: nginx

```
> The nginx.ingress.kubernetes.io/service-upstream annotation disables that behavior and instead uses a single upstream in NGINX, the service's Cluster IP and port.

> The nginx.ingress.kubernetes.io/upstream-vhost annotation allows you to control the value for host in the following statement: 
> proxy_set_header Host $host, which forms part of the location block.


## Debug

```bash
# https://istio.io/latest/docs/tasks/observability/logs/access-log/

$ kubectl -n nginx-ingress logs -f nginx-ingress-controller-7b6d7d4d75-8jw8p -c istio-proxy

```
