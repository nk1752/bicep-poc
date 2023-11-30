# load variables
AKS_NAME='aks-cluster' \
RESOURCE_GROUP='aks-cluster-rg' \
LOCATION='eastus' \
SUBSCRIPTION_ID='df2f960a-8e92-40ec-a2b8-0a2923d3c074' \
IDENTITY_RESOURCE_NAME='azure-alb-identity' \
VM_SIZE='standard_d2s_v2'

echo $AKS_NAME
echo $RESOURCE_GROUP
echo $LOCATION
echo $SUBSCRIPTION_ID
echo $IDENTITY_RESOURCE_NAME
echo $VM_SIZE

az account set --subscription $SUBSCRIPTION_ID

# create RG
az group create --name $RESOURCE_GROUP --location $LOCATION

# update
az aks update -n $AKS_NAME \
    -g $RESOURCE_GROUP \
    --enable-oidc-issuer \
    --enable-workload-identity

# *** create ACR before this command ***
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --location $LOCATION \
    --node-vm-size $VM_SIZE \
    --network-plugin azure \
    --enable-oidc-issuer \
    --enable-workload-identity

# >>> install ALB Controller
# Create a user managed identity for ALB controller and federate the identity as Workload Identity to use in the AKS cluster

mcResourceGroup=$(az aks show -g $RESOURCE_GROUP -n $AKS_NAME --query "nodeResourceGroup" -o tsv)
mcResourceGroupId=$(az group show --name $mcResourceGroup --query id -otsv)
echo $mcResourceGroupId

# create managed identity
az identity create --resource-group $RESOURCE_GROUP --name $IDENTITY_RESOURCE_NAME
principalId="$(az identity show -g $RESOURCE_GROUP -n $IDENTITY_RESOURCE_NAME --query principalId -o tsv)"
echo principal or object id: $principalId

# wait at least 60 sec before role assignment
# Apply "Reader" role to the AKS managed cluster resource group for the newly provisioned identity
az role assignment create --assignee-object-id $principalId \
    --assignee-principal-type ServicePrincipal \
    --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" \
    --scope $mcResourceGroupId

# Set up federation with AKS OIDC issuer
# oidc issuer url of cluster
AKS_OIDC_ISSUER="$(az aks show -n "$AKS_NAME" -g "$RESOURCE_GROUP" --query "oidcIssuerProfile.issuerUrl" -o tsv)" 
echo $AKS_OIDC_ISSUER

# Setup federation with AKS OIDC issuer - ALB Controller requires a federated credential with the name of azure-alb-identity. Any other federated credential name is unsupported.
az identity federated-credential create \
    --name "azure-alb-identity" \
    --identity-name "azure-alb-identity" \
    --resource-group $RESOURCE_GROUP \
    --issuer "$AKS_OIDC_ISSUER" \
    --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# install ALB using Helm
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

azure-alb-identity-id=$(az identity show -g $RESOURCE_GROUP -n azure-alb-identity --query clientId -o tsv)
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
    --version 0.5.024542 \
    --set albController.podIdentity.clientID=$(az identity show -g $RESOURCE_GROUP -n azure-alb-identity --query clientId -o tsv)

kubectl get pods -n azure-alb-system

# >>> MC deployment
echo $AKS_NAME
echo $RESOURCE_GROUP

MC_RESOURCE_GROUP=$(az aks show --name $AKS_NAME --resource-group $RESOURCE_GROUP --query "nodeResourceGroup" -o tsv)
echo $MC_RESOURCE_GROUP
CLUSTER_SUBNET_ID=$(az vmss list -g $MC_RESOURCE_GROUP --query '[0].virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id' -o tsv)
read -d '' VNET_NAME VNET_RESOURCE_GROUP VNET_ID <<< $(az network vnet show --ids $CLUSTER_SUBNET_ID --query '[name, resourceGroup, id]' -o tsv)

SUBNET_ADDRESS_PREFIX='10.225.0.0/24'
ALB_SUBNET_NAME='subnet-alb'
az network vnet subnet create --vnet-name $VNET_NAME
    -g $VNET_RESOURCE_GROUP  
    --name $ALB_SUBNET_NAME 
    --address-prefixes $SUBNET_ADDRESS_PREFIX 
    --delegations 'Microsoft.ServiceNetworking/trafficControllers'

ALB_SUBNET_ID=$(az network vnet subnet show --name $ALB_SUBNET_NAME --resource-group $VNET_RESOURCE_GROUP --vnet-name $VNET_NAME --query '[id]' --output tsv)

# Delegate permissions to managed identity
echo $IDENTITY_RESOURCE_NAME
echo $MC_RESOURCE_GROUP

mcResourceGroupId=$(az group show --name $MC_RESOURCE_GROUP --query id -otsv)
principalId=$(az identity show -g $RESOURCE_GROUP -n $IDENTITY_RESOURCE_NAME --query principalId -otsv)

# Delegate AppGw for Containers Configuration Manager role to AKS Managed Cluster RG
az role assignment create --assignee-object-id $principalId \
    --assignee-principal-type ServicePrincipal \
    --scope $mcResourceGroupId \
    --role "fbc52c3f-28ad-4303-a892-8a056630b8f1"

# Delegate Network Contributor permission for join to association subnet
az role assignment create --assignee-object-id $principalId \
    --assignee-principal-type ServicePrincipal \
    --scope $ALB_SUBNET_ID \
    --role "4d97b98b-1d4f-4787-a291-c67834d212e7"

# >>> namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: alb-test-infra
EOF

# >>> Assocoations
kubectl apply -f - <<EOF
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: alb-test
  namespace: alb-test-infra
spec:
  associations:
  - $ALB_SUBNET_ID
EOF