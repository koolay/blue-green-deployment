helm install --namespace nginx-ingress --set meshProvider=nginx --set crd.create=false  flagger ./flagger -f ./flagger.values.yaml


kubectl label namespace bookinfo istio-injection=enabled
