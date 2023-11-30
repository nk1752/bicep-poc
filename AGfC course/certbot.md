apt install certbot

# generate cert
sudo su
certbot certonly --preferred-challenges=dns --manual --email nk1752@outlook.com --server https://acme-v02.api.letsencrypt.org/directory -d *.learn-nadeem.xyz --agree-tos
certbot certonly --preferred-challenges=dns --manual --email nk1752@outlook.com --server https://acme-v02.api.letsencrypt.org/directory -d *.pocvivahealth.com --agree-tos
certbot certonly --preferred-challenges=dns --manual --email nk1752@outlook.com --server https://acme-v02.api.letsencrypt.org/directory -d *.poc-viva.com --agree-tos

# change permissive
cp /etc/letsencrypt/archive/poc-viva.com/* /tmp/certbot/poc-viva
chmod +r privkey1.pem

openssl x509 -in ./certbot/poc-viva.com/fullchain1.pem -noout -issuer

k create secret tls pocvivahealth.com --namespace infra-ns --key ./certbot/pocvivahealth.com/privkey1.pem --cert ./certbot/pocvivahealth.com/fullchain1.pem
k create secret tls learn-nadeem.xyz --namespace infra-ns --key ./certbot/learn-nadeem.xyz/privkey.pem --cert ./certbot/learn-nadeem.xyz/fullchain.pem
k create secret tls poc-viva.com --namespace infra-ns --key ./certbot/poc-viva.com/privkey1.pem --cert ./certbot/poc-viva.com/fullchain1.pem


kubectl get secret poc-viva.com -n infra-ns -o jsonpath='{.data}'
kubectl get secret pocvivahealth.com -n infra-ns -o jsonpath='{.data}'

echo 'UyFCXCpkJHpEc2I9' | base64 --decode

kubectl get secret learn-tls-secret -o jsonpath='{.data.password}' | base64 --decode