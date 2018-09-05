#! /bin/sh -x 

CI_PROJECT_NAME=gitlabci-demo-nodejs-frontend
KUBE_NAMESPACE=autodeploy
CI_PROJECT_DIR=/home/heyj/workspace/git/wingkaiho/k8s-notes/gitlab-ci/script
CI_INIT_REPLICATES=1

function get_deployment_replicates() {
    name=${1}
    namespace=${2}

    if [[ -n $name ]] && [[ -n $namespace ]]; then
        replicates=`kubectl get deployment -n $namespace $name  | sed -n "2,1p" | awk -F ' ' '{print $2}' `
    elif [[ -n $name ]]; then
        replicates=`kubectl get deployment -n $namespace $name  | sed -n "2,1p" | awk -F ' ' '{print $2}' `
    else
        replicates=0
    fi

    if [[ ! -n $replicates ]]; then
        replicates=0
    fi

    echo $replicates
}

function cal_canary_replicates() {
    prod_replicates=${1}
    canary_precentage=${2}

    prod_precentage=$((100 - $canary_precentage))
    all_replicates=$(awk 'BEGIN{printf "%.2f\n",('$prod_replicates'/ ( '$prod_precentage' / 100))}')
    all_replicates=${all_replicates%.*}
    canary_replicates=$(( $all_replicates - $prod_replicates ))

    if [[ $canary_replicates -gt 0 ]]; then
        echo "$canary_replicates"
    else
        echo 1
    fi
}

function deploy() {
    track=${1:-stable}
    replicates=${2}
    name=${CI_PROJECT_NAME}
   
    if [[ "$track" != "stable" ]]; then
        name="$name-$track"
    fi

    sed -i "s/__CI_ENVIRONMENT_DEPLOY_NAME_SLUG__/${name}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__CI_ENVIRONMENT_APP_NAME_SLUG__/${CI_PROJECT_NAME}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__CI_ENVIRONMENT_APP_TRACK_SLUG__/${track}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__CI_ENVIRONMENT_APP_REPLICATES_SLUG__/${replicates}/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    sed -i "s/__CI_ENVIRONMENT_APP_VERSION_SLUG__/ab095e9b/g" ${CI_PROJECT_DIR}/yaml/tmpl/*.yaml
    #kubectl apply -f ${CI_PROJECT_DIR}/yaml/tmpl/ -n ${KUBE_NAMESPACE}
    #kubectl get pod -n ${KUBE_NAMESPACE}
}

function delete() {
	track="${1-stable}"
    name=${CI_PROJECT_NAME}

    if [[ "$track" != "stable" ]]; then
      name="$name-$track"
    fi

    if [[ -n "$(kubectl get deployment -n ${KUBE_NAMESPACE} $name)" ]]; then
      #helm delete "$name"
	  echo $name exist
    fi
    
}

# 检查线上当前备份数据，如果不存在，以CI_INIT_REPLICATES为准
function cal_stable_deployment_replicates() {
	name=${CI_PROJECT_NAME}

	replicates=$(get_deployment_replicates ${name} ${KUBE_NAMESPACE})

	if [[ $replicates -gt 0 ]]; then
        echo ${replicates}
	else
		echo ${CI_INIT_REPLICATES}
    fi
	
}

export prod_replicates=$(get_deployment_replicates ${CI_PROJECT_NAME} ${KUBE_NAMESPACE})
export canary_replicates=$(cal_canary_replicates ${prod_replicates} 50)
echo prod_replicates ${prod_replicates}
echo canary_replicates ${canary_replicates}
deploy canary ${canary_replicates}
delete canary
delete cann 
export replicates=$(cal_stable_deployment_replicates)
echo $replicates
