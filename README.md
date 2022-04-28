# Requirements (TODO)
  cfssl: follow instructions on how to install or `go get github.com/cloudflare/cfssl/cmd/...` (must be inside a module (have go.mod in directory you're executing the `go get` command))

  pip install pyyaml cryptography ansible

  kubectl: follow instructions, use native package management

# Kubernetes The Hard Way - AWS - Terraform, Ansible

This project is based on [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) and [Kubernetes The Hard Way - AWS](https://github.com/slawekzachcial/kubernetes-the-hard-way-aws). It takes [Kubernetes The Hard Way - AWS](https://github.com/slawekzachcial/kubernetes-the-hard-way-aws) a step further by using Terraform to provision AWS resources, Ansible for configuration management, and Python and shell scripts for various glue code. It automates the whole process of bringing up a Kubernetes cluster while maintaining a lab-style flow and file structure similar to [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way). It was created for the purpose of learning Kubernetes.


To quote [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way):

> Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

> The results of this tutorial should not be viewed as production ready, and may receive limited support from the community, but don't let that stop you from learning!

One should be a little bit familiar with [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) and [Kubernetes The Hard Way - AWS](https://github.com/slawekzachcial/kubernetes-the-hard-way-aws) before using this project.

## AWS Costs Disclaimer

This project uses AWS resources. The authors shall not be responsible for AWS costs that this project might incur.

## Usage

1. Make sure you have satisfied the prerequisites (TODO)

2. Install the client tools (TODO)

3. Clone this repository

4. Change directory into the clone repository

5. Change the Terraform backend to your backend. If you're not familiar with Terraform, it's probably better to just use a local backend. Make sure that git ignores the backend/state files that will be produced when running Terraform (TODO).

6. `make build` will build your Kubernetes cluster

7. `make destroy` will delete all provisioned resources

## Configuration

You can change the configuration file, `config.yml`, to suit your needs. Under the `controllers` and `workers` block, you can change the number of instances used as Kubernetes controllers and workers. Just make sure the names, IP addresses, etc. don't conflict with each other.

## Idempotency

Only section 13, the smoke test, is idempotent. There may be other sections or parts of other sections that are idempotent but I haven't kept track of which ones are idempotent.

## TODO

- [ ] Automate the checking of prerequisites

- [ ] Check if client tools are installed

- [ ] Write clearer explanation of how to deal with Terraform backend

- [ ] Write tests
