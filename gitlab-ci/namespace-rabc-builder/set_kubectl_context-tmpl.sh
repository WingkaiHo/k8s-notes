#! /bin/sh

KUBE_URL=https://__KUBE_ClUSTER_URL__
KUBE_NAMESPACE=__YOUR_GITLAB_BUILD_NAMESPACE__


kubectl config set-cluster default-cluster --server=${KUBE_URL} --certificate-authority=./ca.crt
kubectl config set-credentials default-admin --token=`cat token`
kubectl config set-context default-system --cluster=default-cluster --user=default-admin --namespace ${KUBE_NAMESPACE}
kubectl config use-context default-system

echo "context switch successful....."
