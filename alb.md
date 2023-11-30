# load variables
AKS_NAME='agfc-cluster' \
RESOURCE_GROUP='agfc-rg' \
LOCATION='eastus' \
SUBSCRIPTION_ID='df2f960a-8e92-40ec-a2b8-0a2923d3c074' \
TENANT_ID='7cb752a7-6dfd-429e-adc9-129f0ea3fcec' \
IDENTITY_RESOURCE_NAME='azure-alb-identity' \
VM_SIZE='standard_d2s_v2'

echo $AKS_NAME
echo $RESOURCE_GROUP
echo $LOCATION
echo $SUBSCRIPTION_ID
echo $IDENTITY_RESOURCE_NAME
echo $VM_SIZE


az account set --subscription $SUBSCRIPTION_ID

# Register required resource providers on Azure.
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.NetworkFunction
az provider register --namespace Microsoft.ServiceNetworking

# Install Azure CLI extensions.
az extension add --name alb

# create RG
az group create --name $RESOURCE_GROUP --location $LOCATION

# *** create ACR before this command ***
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --location $LOCATION \
    --node-vm-size $VM_SIZE \
    --network-plugin azure \
    --enable-oidc-issuer \
    --enable-workload-identity

# update AKS
az aks update -g $RESOURCE_GROUP -n $AKS_NAME --enable-oidc-issuer --enable-workload-identity --no-wait


az aks get-credentials -n $AKS_NAME -g $RESOURCE_GROUP
kubectl get pod -A -o wide
kubectl get events --all-namespaces  --sort-by='.metadata.creationTimestamp'
az aks update -n $AKS_NAME \
    -g $RESOURCE_GROUP \
    --enable-oidc-issuer \
    --enable-workload-identity

# install ALB Controller
# Create a user managed identity for ALB controller and federate the identity as Workload Identity to use in the AKS cluster

# get MC resource group ID
mcResourceGroup=$(az aks show -g $RESOURCE_GROUP -n $AKS_NAME --query "nodeResourceGroup" -o tsv)
echo $mcResourceGroup
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
    --scope $mcResourceGroupId \
    --debug


# Set up federation with AKS OIDC issuer
# oidc issuer url of cluster
AKS_OIDC_ISSUER="$(az aks show -n "$AKS_NAME" -g "$RESOURCE_GROUP" --query "oidcIssuerProfile.issuerUrl" -o tsv)" 
echo $AKS_OIDC_ISSUER

# Setup federation with AKS OIDC issuer - ALB Controller requires a federated credential with the name of azure-alb-identity. Any other federated credential name is unsupported.
az identity federated-credential create \
    --name "azure-alb-identity" \
    --identity-name "$IDENTITY_RESOURCE_NAME" \
    --resource-group $RESOURCE_GROUP \
    --issuer "$AKS_OIDC_ISSUER" \
    --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# install ALB using Helm
helm-resource-namespace
alb-controller-namespace
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

# get azure-alb-identity client id
clientId="$(az identity show -g $RESOURCE_GROUP -n azure-alb-identity --query clientId -o tsv)"
echo $clientId
# install ALB Controller
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
    --version 0.6.1 \
    --set albController.podIdentity.clientID=$(az identity show -g $RESOURCE_GROUP -n azure-alb-identity --query clientId -o tsv)

