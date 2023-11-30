alias k=kubectl

k apply -f ./manifest/gateway.yml 
k describe gateway shared-gateway --namespace infra-ns
k delete gateway shared-gateway --namespace infra-ns

k delete httproute nginx-route --namespace nginx-ns