#! /bin/bash

export CI_PROJECT_NAME=gitlab-cd-demo
export CI_BUILD_STAGE=production
export CI_COMMIT_SHA=12345678
export KUBE_APP_NAME=${CI_PROJECT_NAME}-${CI_BUILD_STAGE}
export DOCKER_IMAGE="${CI_PROJECT_NAME}:${CI_COMMIT_SHA:0:8}"
export SERVICE=gitlab-cd-demo
export KUBE_NAMESPACE=gitlab-cd-demo-670
export ROLLOUT_PERCENTAGE=33

function set_kubectl_context() {
    kubectl config set-cluster default-cluster --server=${KUBE_URL} --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
    kubectl config set-credentials default-admin --token=${KUBE_TOKEN}
    kubectl config set-context default-system --cluster=default-cluster --user=default-admin --namespace ${KUBE_NAMESPACE}
    kubectl config use-context default-system
}

function run_deploy() {
    replicates=${1}

    echo "replace VALs."
    sed -i "s/__KUBE_APP_NAME__/${KUBE_APP_NAME}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__KUBE_NAMESPACE__/${KUBE_NAMESPACE}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__CI_BUILD_STAGE__/${CI_BUILD_STAGE}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__KUBE_POD_REPLICATES__/${replicates}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__DOCKER_IMAGE__/${DOCKER_IMAGE}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__KUBE_REGISTRY_DOMAIN__/${KUBE_REGISTRY_DOMAIN}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__NODE_ENV__/${NODE_ENV}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__CI_ENVIRONMENT_SLUG__/${CI_ENVIRONMENT_SLUG}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    
    echo "ensure namespace: ${KUBE_NAMESPACE}"
    kubectl create namespace ${KUBE_NAMESPACE} 2>/dev/null || /bin/true

    echo "apply yaml files."
    kubectl apply -f ${CI_PROJECT_DIR}/yaml/tmpl/ -n ${KUBE_NAMESPACE}
}

function show_k8s_info() {\
    kubectl get pod -n ${KUBE_NAMESPACE}
    kubectl get svc -n ${KUBE_NAMESPACE}
    kubectl get ingress -n  ${KUBE_NAMESPACE}
}

# 获取对应版本deployment实例数目
function get_deployment_replicas() {
    name=${1}
    replicates=`kubectl get deployment -n ${KUBE_NAMESPACE} $name 2>/dev/null  | sed -n "2,1p" | awk -F ' ' '{print $2}' `

    if [[ $replicates -gt 0 ]]; then
        echo ${replicates}
    else
        echo 0
    fi
}

# 获取生产环境实例数目
function get_production_replicas() {       
    # 获得环境真实运行的实例数
    # 因为k8s可能已经将实例数量扩容了，此时用默认值就不恰当了

    # 生产版本deployment实例数目
    deployment_prod_replicas=$(get_deployment_replicas ${CI_PROJECT_NAME}-production)
    # 获取rollout版本deployment实例数目
    deployment_rollout_replicas=$(get_deployment_replicas ${CI_PROJECT_NAME}-rollout)

    # 生产环境实例数目=生产版本deployment实例数目+rollout版本deployment实例数目
    PRODUCTION_REPLICAS=$((${deployment_prod_replicas} + ${deployment_rollout_replicas}))

    if [[ ${PRODUCTION_REPLICAS} -gt 0 ]]; then
        # 保持实例数不变
        echo ${PRODUCTION_REPLICAS}
    else
        # 实例数用默认值
        PRODUCTION_REPLICAS=${DEFAULT_REPLICATES}
        echo ${PRODUCTION_REPLICAS} 
    fi
}

# 计算rollout/production deployment备份数目
function get_replicas() {
    percentage="${1:-100}"

    replicas=${PRODUCTION_REPLICAS}
    replicas="$(($replicas * $percentage / 100))"

    # always return at least one replicas
    if [[ $replicas -gt 0 ]]; then
      echo "$replicas"
    else
      echo 1
    fi
}

function get_replicas_ex() {	
    percentage="${1:-100}"

    replicas=${PRODUCTION_REPLICAS}
    #replicas="$(($replicas * $percentage / 100))"
	replicas=$(awk 'BEGIN{printf "%.2f\n",('$replicas' * '$percentage' / 100 ) }')

	echo ${replicas}
	ret=$(printf "%.0f\n" $replicas)
	echo ${ret}
}

# scale replica of prod deployment
function scale_prod_deployment() {
    percentage=${1:-100}
    name=${CI_PROJECT_NAME}-production

	echo "production percentage: ${percentage}"
    replicas=$(get_replicas "${percentage}")
    echo "production replicas: ${replicas}"
    if [[ -n "$(kubectl get deployment -n ${KUBE_NAMESPACE} | grep ${name})" ]]; then
        echo "scale deployment/${name}"
        #kubectl scale -n ${KUBE_NAMESPACE} --replicas=${replicas} deployment/${name}
    fi
}

function deploy_rollout {
  percentage=${1}
  app_name=${CI_PROJECT_NAME}-rollout
  stage="rollout"

  
  echo "rollout percentage: ${percentage}"
  replicas=$(get_replicas "${percentage}")
  echo "rollout replicas: ${replicas}"
  # create the rollout deployment
  #echo "replace VALs."
  #sed -i "s/__KUBE_APP_NAME__/${app_name}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
  #sed -i "s/__KUBE_NAMESPACE__/${KUBE_NAMESPACE}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
  #sed -i "s/__CI_BUILD_STAGE__/${stage}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
  #sed -i "s/__KUBE_POD_REPLICATES__/${replicates}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
  #sed -i "s/__DOCKER_IMAGE__/${DOCKER_IMAGE}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
  #sed -i "s/__KUBE_REGISTRY_DOMAIN__/${KUBE_REGISTRY_DOMAIN}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
  #sed -i "s/__NODE_ENV__/${NODE_ENV}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
  #sed -i "s/__CI_ENVIRONMENT_SLUG__/${CI_ENVIRONMENT_SLUG}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml

  #echo "apply yaml files."
  #kubectl apply -f ${CI_PROJECT_DIR}/yaml/tmpl/ -n ${KUBE_NAMESPACE}
}

function delete_rollout() {
  name=${CI_PROJECT_NAME}-rollout
  kubectl delete deployment ${name} -n ${KUBE_NAMESPACE} 2>/dev/null || /bin/true
}


function clean_kube() {
    kubectl delete service -l app=${CI_ENVIRONMENT_SLUG} -l service=${SERVICE}-n ${KUBE_NAMESPACE}
    kubectl delete deployment -l app=${CI_ENVIRONMENT_SLUG} -l service=${SERVICE} -n ${KUBE_NAMESPACE}
    #kubectl delete ingress -l app=${CI_ENVIRONMENT_SLUG} -l service=${SERVICE} -n ${KUBE_NAMESPACE}
}

export PRODUCTION_REPLICAS=$(get_production_replicas)
deploy_rollout $ROLLOUT_PERCENTAGE
scale_prod_deployment $((100-ROLLOUT_PERCENTAGE))
echo ${PRODUCTION_REPLICAS}
get_replicas_ex $ROLLOUT_PERCENTAGE
get_replicas_ex $((100 - ROLLOUT_PERCENTAGE))
#show_k8s_info
