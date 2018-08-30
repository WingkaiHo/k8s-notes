#! /bin/bash

function get_k8s_rbac_info() {
	namespace=${1}
	name=admin-${namespace}

	token_name=`kubectl -n gitlab-cd-demo get secret | grep ${name}-token | awk -F ' ' '{print $1}'`
	# Write token file
	kubectl -n ${namespace} get secret ${token_name} -o jsonpath={.data.token}|base64 -d > ${namespace}/token
	# Write ca.crt file 
	kubectl get secret -n gitlab-cd-demo admin-gitlab-cd-demo-token-s8pf4 -o jsonpath="{['data']['ca\.crt']}" | base64 -d > ${namespace}/ca.crt
}

function usage() {
	echo "usage: create-namepspace-admin-role.sh <namespaec> <kube-url>"
	echo "example: create-namepspace-admin-role.sh gitlab-cd-demo 172.25.52.216:6443"
}

# main 
namespace=${1}
kube_url=${2}

if [[ -z ${namespace} ]]; then
	echo "请输入你创建权限对应的namepace"
	usage
	exit 1
fi

if [[ -z ${kube_url} ]]; then
	echo "请输入kube_url: 172.25.52.215:6443"
	usage
	exit 1
fi

mkdir -p ${namespace}

echo "Create ${namespace}/admin-${namespace}-rabc.yaml from template..."
sed "s/__YOUR_GITLAB_BUILD_NAMESPACE__/${namespace}/g" rabc-tmpl.yaml > ${namespace}/admin-${namespace}-rabc.yaml
echo "Create rabc in namespace ${namespace}"
kubectl apply -f ${namespace}/admin-${namespace}-rabc.yaml

echo "Download ca.crt and rabc token to directory ${namespace}"
get_k8s_rbac_info ${namespace}

echo "Create set_kubectl_context.sh in directory ${namespace}"
cp set_kubectl_context-tmpl.sh ${namespace}/set_kubectl_context.sh 
sed -i "s/__YOUR_GITLAB_BUILD_NAMESPACE__/${namespace}/g" ${namespace}/set_kubectl_context.sh
sed -i "s/__KUBE_ClUSTER_URL__/${kube_url}/g" ${namespace}/set_kubectl_context.sh

