export SCALEWAY_ORGANIZATION="..."
export SCALEWAY_TOKEN="..."
terraform apply -target=scaleway_server.manager -target=scaleway_ip.manager_ip  -var managers=1 -var swarm_init=true
terraform refresh
export TF_VAR_swarm_worker_token=$(ssh root@$(terraform output manager_external) docker swarm join-token -q worker)
export TF_VAR_swarm_manager_token=$(ssh root@$(terraform output manager_external) docker swarm join-token -q manager)
export TF_VAR_swarm_manager_ip=$(terraform output manager_internal)
terraform apply
