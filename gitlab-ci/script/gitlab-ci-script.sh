#! /bin/sh -x


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
replicas=$(get_deployment_replicates gitlabci-demo-nodejs-frontend autodeploy)
echo $replicas

cal_canary_replicates $replicas 50
