name := kubernetes-the-hard-way-aws

_main_dir := $(dir $(abspath $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))
_main_dir := $(_main_dir:/=)

_main_app_dir := ${_main_dir}

_main_config_file := ${_main_dir}/config.yml

_main_secrets_dir := $(abspath ${_main_app_dir}/secrets)
_main_key_pair_file := ${_main_secrets_dir}/${name}.ed25519

_main_sections_dir := ${_main_dir}/sections

_main_inventory_dir := /tmp/${name}/ansible-inventory

# TODO: DEBUG
_main_certs_dir := ${_main_secrets_dir}/test-certs

_main_terraform_cmd := ${_main_app_dir}/terraform.sh

plan:
	"${_main_terraform_cmd}" plan

apply:
	"${_main_terraform_cmd}" apply

destroy:
	"${_main_terraform_cmd}" destroy

debug:
	"${_main_sections_dir}/13-smoke-test/07-create-nginx-node-port-firewall-rule.sh"
# 	"${_main_sections_dir}/13-smoke-test/09-curl-nginx-test.py"

build:
	cd "${_main_dir}" && \
	make apply  && \
	"${_main_sections_dir}/04-provisioning-a-ca-and-generating-tls-certificates/run.py" \
		"${name}" \
		"${_main_config_file}" && \
	"${_main_sections_dir}/05-generating-kubernetes-configuration-files-for-authentication/run.py" \
		"${name}" \
		"${_main_config_file}" && \
	"${_main_sections_dir}/06-generating-the-data-encryption-config-and-key/run.py" && \
	"${_main_sections_dir}/07-bootstrapping-the-etcd-cluster/run-cm.py" \
		"${name}" \
		"${_main_config_file}" \
		"${_main_key_pair_file}" \
		"${_main_inventory_dir}" && \
	"${_main_sections_dir}/08-bootstrapping-the-kubernetes-control-plane/01-run-cm.py" \
		"${name}" \
		"${_main_config_file}" \
		"${_main_key_pair_file}" \
		"${_main_inventory_dir}" && \
	"${_main_sections_dir}/08-bootstrapping-the-kubernetes-control-plane/03-the-kubernetes-frontend-load-balancer_verification.py" \
		"${name}" \
		"${_main_config_file}" && \
	"${_main_sections_dir}/09-bootstrapping-the-kubernetes-worker-nodes/run-cm.py" \
		"${name}" \
		"${_main_config_file}" \
		"${_main_key_pair_file}" \
		"${_main_inventory_dir}" && \
	"${_main_sections_dir}/10-configuring-kubectl-for-remote-access/run.py" \
		"${name}" \
		"${_main_config_file}" && \
	"${_main_sections_dir}/11-provisioning-pod-network-routes/02-verification.sh" && \
	"${_main_sections_dir}/12-deploying-the-dns-cluster-add-on/01-run-cm.py" \
		"${name}" \
		"${_main_config_file}" \
		"${_main_key_pair_file}" \
		"${_main_inventory_dir}" && \
	"${_main_sections_dir}/12-deploying-the-dns-cluster-add-on/02-run.sh" && \
	"${_main_sections_dir}/13-smoke-test/01-data-encryption-and-nginx.py" \
		"${name}" \
		"${_main_config_file}" \
		"${_main_key_pair_file}" && \
	"${_main_sections_dir}/13-smoke-test/02-port-forward-localhost-curl-test.py" && \
	"${_main_sections_dir}/13-smoke-test/03-logs-and-exec.py" && \
	"${_main_sections_dir}/13-smoke-test/04-create-nginx-service.py" && \
	"${_main_sections_dir}/13-smoke-test/07-create-nginx-node-port-firewall-rule.sh" "${name}" && \
	"${_main_sections_dir}/13-smoke-test/09-curl-nginx-test.py"

reset:
	cd "${_main_dir}" && \
	rm -rf "${_main_certs_dir}" && \
	make destroy && \
	make delete-key-pair && \
	make key-pair && \
	make build

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
