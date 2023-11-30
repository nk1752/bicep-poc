# ****** Application Gateway for Containers components ******

# Name of the Application Gateway for Containers resource to be created
echo $RESOURCE_GROUP
AGFC_NAME='alb-poc' 
az network alb create -g $RESOURCE_GROUP -n $AGFC_NAME

FRONTEND_NAME='prisma-frontend'
az network alb frontend create -g $RESOURCE_GROUP -n $FRONTEND_NAME --alb-name $AGFC_NAME

VNET_NAME='agfc-vnet' \
VNET_RESOURCE_GROUP='agfc-rg' \
ALB_SUBNET_NAME='alb-subnet'

# add delegation for Application Gateway for Containers of type Microsoft.ServiceNetworking/trafficControllers
az network vnet subnet update --resource-group $VNET_RESOURCE_GROUP --name $ALB_SUBNET_NAME --vnet-name $VNET_NAME --delegations 'Microsoft.ServiceNetworking/trafficControllers'
ALB_SUBNET_ID=$(az network vnet subnet list --resource-group $VNET_RESOURCE_GROUP --vnet-name $VNET_NAME --query "[?name=='$ALB_SUBNET_NAME'].id" -o tsv)
echo $ALB_SUBNET_ID

# Delegate permissions to managed identity - azure-alb-identity
resourceGroupId=$(az group show --name $RESOURCE_GROUP --query id -o tsv)
echo $resourceGroupId
principalId=$(az identity show -g $RESOURCE_GROUP -n $IDENTITY_RESOURCE_NAME --query principalId -o tsv)
echo $principalId

# Delegate AppGw for "Containers Configuration Manager" role to RG containing Application Gateway for Containers resource
az role assignment create --assignee-object-id $principalId \
    --assignee-principal-type ServicePrincipal \
    --scope $resourceGroupId \
    --role "fbc52c3f-28ad-4303-a892-8a056630b8f1"

# Delegate "Network Contributor" permission for join to association subnet
az role assignment create --assignee-object-id $principalId \
    --assignee-principal-type ServicePrincipal \
    --scope $ALB_SUBNET_ID \
    --role "4d97b98b-1d4f-4787-a291-c67834d212e7"



//  <<< BYO >>>
# create association resource
ASSOCIATION_NAME='association-poc'
az network alb association create -g $RESOURCE_GROUP -n $ASSOCIATION_NAME --alb-name $AGFC_NAME --subnet $ALB_SUBNET_ID


# ***** Deployment *****
kubectl apply -f https://trafficcontrollerdocs.blob.core.windows.net/examples/traffic-split-scenario/deployment.yaml

echo $RESOURCE_GROUP
echo $AGFC_NAME

RESOURCE_ID=$(az network alb show -g $RESOURCE_GROUP -n $AGFC_NAME --query id -o tsv)
echo $FRONTEND_NAME

# create Gateway
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: gateway-01
  namespace: default
  annotations:
    alb.networking.azure.io/alb-id: $RESOURCE_ID
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
  addresses:
  - type: alb.networking.azure.io/alb-frontend
    value: prisma-fe
EOF