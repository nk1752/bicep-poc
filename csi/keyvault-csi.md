az aks enable-addons --addons azure-keyvault-secrets-provider -n agfc-cluster -g agfc-rg
az aks addon update -n agfc-cluster -g agfc-rg -a azure-keyvault-secrets-provider --enable-secret-rotation


kubectl exec busybox-secrets-store01-inline -- ls /mnt/secrets-store/
kubectl exec busybox-secrets-store-inline -- cat /mnt/secrets-store/poc-cert

kubectl exec busybox-secrets-store-inline -- cat /mnt/secrets-store/nadeem

kubectl create secret generic db-user-pass \
    --from-literal=username=admin \
    --from-literal=password='S!B\*d$zDsb='

kubectl get secrets
kubectl describe secret db-user-pass

# SecretProviderClass

IDENTITY_CLIENT_ID="$(az identity show -g <resource-group> --name <identity-name> --query 'clientId' -o tsv)"
IDENTITY_CLIENT_ID="fcf36a1c-15f3-4fb5-b183-f4b2eb2fcac7"
