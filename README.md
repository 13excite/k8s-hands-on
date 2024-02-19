# K8S hands-on tasks

Repo contains tasks for diffetent topics of k8s. The main goal is to better
understand the concepts of k8s and be able to solve problems that arise.

## Installation

Run script:

```bash
bash setup.sh
```

## Clean

Run script:

```bash
bash wipe_cluster.sh
```

## Description of tasks

The repo contains 5 tasks distributed across namespaces, the task is considered completed
when `curl` returns 200 response code and the next body.

```bash
## The host header changes depending on the task number
# curl localhost:80/ok/test -H 'Host: testapp3.com'
{"status":"OK"}
```

## Requirements

- Installed Docker
- Installed kind for creating local k8s-cluster [quick-start](https://kind.sigs.k8s.io/docs/user/quick-start/)
- Installed kubectx and kubens [kubectx-repo](https://github.com/ahmetb/kubectx)
- Documentation below read (need to understand basic concepts)

## Documentation

- [k8s quick-reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/)
- [services](https://kubernetes.io/docs/concepts/services-networking/service/)
- [deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [rollbacks](https://learnk8s.io/kubernetes-rollbacks)
- [configmaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [storages](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
