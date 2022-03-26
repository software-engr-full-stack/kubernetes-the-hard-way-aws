name := kubernetes-the-hard-way-aws

_sections_dir := $(dir $(abspath $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))
_sections_dir := $(_sections_dir:/=)

_sections_app_dir := $(abspath ${_sections_dir}/..)

_sections_config_file := ${_sections_dir}/config.yml

_sections_secrets_dir := $(abspath ${_sections_app_dir}/secrets)

_sections_certs_dir := ${_sections_secrets_dir}/test-certs
_sections_auto_gen_config_dir := ${_sections_secrets_dir}/config-auto-gen
_sections_key_pair_file := ${_sections_secrets_dir}/${name}.ed25519

_sections_hostnames := controller-0 controller-1 controller-2 worker-0 worker-1 worker-2

debug:
	"${_sections_app_dir}/lib/public_addresses.py" ${_sections_hostnames}

build:
	cd "${_sections_dir}" && \
	"${_sections_dir}/04-provisioning-a-ca-and-generating-tls-certificates/run.py" \
		"${_sections_certs_dir}" \
		"${_sections_config_file}" \
		"${_sections_app_dir}/lib/public_addresses.py" ${_sections_hostnames}

# build: delete-key-pair key-pair
# 	cd "${_sections_dir}" && \
# 	terraform apply -auto-approve && \
# 	"${_sections_dir}/04-provisioning-a-ca-and-generating-tls-certificates/run.sh" && \
# 	"${_sections_dir}/05-generating-kubernetes-configuration-files-for-authentication/run.sh" && \
# 	"${_sections_dir}/06-generating-the-data-encryption-config-and-key/run.sh" && \
# 	sync && \
# 	sleep 5 && \
# 	"${_sections_dir}/07-bootstrapping-the-etcd-cluster/run.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/08-bootstrapping-the-kubernetes-control-plane/01-run.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/08-bootstrapping-the-kubernetes-control-plane/03-the-kubernetes-frontend-load-balancer_verification.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/09-bootstrapping-the-kubernetes-worker-nodes/01-run.sh" && \
# 	sleep 5 && \
# 	"${_sections_dir}/09-bootstrapping-the-kubernetes-worker-nodes/02-verification-using-controller.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/10-configuring-kubectl-for-remote-access/run.sh" && \
# 	"${_sections_dir}/11-provisioning-pod-network-routes/02-verification.sh" && \
# 	"${_sections_dir}/12-deploying-the-dns-cluster-add-on/01-run.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/12-deploying-the-dns-cluster-add-on/02-run.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/13-smoke-test/01-run.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/13-smoke-test/02-port-forward-localhost-curl-test.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/13-smoke-test/03-logs-and-exec.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/13-smoke-test/04-create-nginx-service.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/13-smoke-test/07-create-nginx-node-port-firewall-rule.sh" && \
# 	sleep 2 && \
# 	"${_sections_dir}/13-smoke-test/09-curl-nginx-test.sh"

key-pair:
	mkdir -p "$$(dirname "${_sections_key_pair_file}")" && \
	[ -f "${_sections_key_pair_file}" ] || \
	aws ec2 create-key-pair \
	  --key-name "${name}" \
	  --key-type 'ed25519' \
	  --output text --query 'KeyMaterial' \
	  > "${_sections_key_pair_file}" && \
	chmod 600 "${_sections_key_pair_file}"

delete-key-pair:
	aws ec2 delete-key-pair --key-name "${name}" && \
	rm "${_sections_key_pair_file}"

.PHONY: build key-pair delete-key-pair
