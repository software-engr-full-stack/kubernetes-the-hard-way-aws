name := kubernetes-the-hard-way-aws

_main_dir := $(dir $(abspath $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))
_main_dir := $(_main_dir:/=)

_main_app_dir := ${_main_dir}

_main_config_file := ${_main_dir}/config.yml

_main_secrets_dir := $(abspath ${_main_app_dir}/secrets)
_main_key_pair_file := ${_main_secrets_dir}/${name}.ed25519

_main_sections_dir := ${_main_dir}/sections

_main_inventory_dir := /tmp/${name}/ansible-inventory
# _main_inventory_file_workers := /temp/current/${name}/ubuntu-focal_aws_workers.inventory
# _main_inventory_file_controllers := /temp/current/${name}/ubuntu-focal_aws_controllers.inventory

# TODO: DEBUG
_main_certs_dir := ${_main_secrets_dir}/test-certs

_main_terraform_cmd := ${_main_sections_dir}/03-provisioning-compute-resources/run.sh

plan:
	"${_main_terraform_cmd}" "${name}" plan

apply:
	"${_main_terraform_cmd}" "${name}" apply

destroy:
	"${_main_terraform_cmd}" "${name}" destroy

debug:
	"${_main_sections_dir}/08-bootstrapping-the-kubernetes-control-plane/run.py" \
		"${name}" \
		"${_main_config_file}" \
		"${_main_key_pair_file}" \
		"${_main_inventory_dir}"

new-build:
	cd "${_main_dir}" && \
	make apply  && \
	"${_main_sections_dir}/04-provisioning-a-ca-and-generating-tls-certificates/run.py" \
		"${name}" \
		"${_main_config_file}" && \
	"${_main_sections_dir}/05-generating-kubernetes-configuration-files-for-authentication/run.py" \
		"${name}" \
		"${_main_config_file}" && \
	"${_main_sections_dir}/06-generating-the-data-encryption-config-and-key/run.py" && \
	"${_main_sections_dir}/07-bootstrapping-the-etcd-cluster/run.py" \
		"${name}" \
		"${_main_config_file}" \
		"${_main_key_pair_file}" \
		"${_main_inventory_dir}"

reset:
	cd "${_main_dir}" && \
	rm -rf "${_main_certs_dir}" && \
	make destroy && \
	make delete-key-pair && \
	make key-pair && \
	make new-build

# build: delete-key-pair key-pair
# 	cd "${_main_dir}" && \
#   terraform init && \
# 	terraform apply -auto-approve && \
# 	"${_main_dir}/04-provisioning-a-ca-and-generating-tls-certificates/run.sh" && \
# 	"${_main_dir}/05-generating-kubernetes-configuration-files-for-authentication/run.sh" && \
# 	"${_main_dir}/06-generating-the-data-encryption-config-and-key/run.sh" && \
# 	sync && \
# 	sleep 5 && \
# 	"${_main_dir}/07-bootstrapping-the-etcd-cluster/run.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/08-bootstrapping-the-kubernetes-control-plane/01-run.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/08-bootstrapping-the-kubernetes-control-plane/03-the-kubernetes-frontend-load-balancer_verification.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/09-bootstrapping-the-kubernetes-worker-nodes/01-run.sh" && \
# 	sleep 5 && \
# 	"${_main_dir}/09-bootstrapping-the-kubernetes-worker-nodes/02-verification-using-controller.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/10-configuring-kubectl-for-remote-access/run.sh" && \
# 	"${_main_dir}/11-provisioning-pod-network-routes/02-verification.sh" && \
# 	"${_main_dir}/12-deploying-the-dns-cluster-add-on/01-run.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/12-deploying-the-dns-cluster-add-on/02-run.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/13-smoke-test/01-run.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/13-smoke-test/02-port-forward-localhost-curl-test.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/13-smoke-test/03-logs-and-exec.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/13-smoke-test/04-create-nginx-service.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/13-smoke-test/07-create-nginx-node-port-firewall-rule.sh" && \
# 	sleep 2 && \
# 	"${_main_dir}/13-smoke-test/09-curl-nginx-test.sh"

key-pair:
	mkdir -p "$$(dirname "${_main_key_pair_file}")" && \
	[ -f "${_main_key_pair_file}" ] || \
	aws ec2 create-key-pair \
	  --key-name "${name}" \
	  --key-type 'ed25519' \
	  --output text --query 'KeyMaterial' \
	  > "${_main_key_pair_file}" && \
	chmod 600 "${_main_key_pair_file}"

delete-key-pair:
	aws ec2 delete-key-pair --key-name "${name}" && \
	rm "${_main_key_pair_file}"

.PHONY: build key-pair delete-key-pair

tests:
	cd ./tests && ./run.sh

.PHONY: tests
