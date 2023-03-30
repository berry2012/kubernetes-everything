# some reference links

https://www.freecodecamp.org/news/how-to-pass-the-certified-kubernetes-security-specialist-exam/

# LAB
aws ec2 describe-instances --filters "Name=tag:project,Values=k8s-kubeadm" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, InstanceId, PrivateIpAddress, PublicIpAddress, [Tags[?Key==`Name`].Value] [0][0]]' --output text --region ${REGION} --profile work


# 1. -------  Network Policy ----------

Default deny - block all traffic except for what is needed. 

#------ demo - pods communication ---------

# 1. create sample deployment that creates a pod
kubectl create deployment nginx --image=nginx:1.14.2 --port=80 -n nptest $do > nginx-dep.yml
# 2. Get the pod IP
kg po -o wide
192.168.194.65 ---> IP of the pod above

# 3. Create another pod that connects to the pod above
kubectl run client --image=radial/busyboxplus:curl -n nptest $do --command -- sh -c  "while true; do curl -m 3 192.168.194.65; sleep 5; done" > client.yml
client --> curl --> nginx-pod 

# 4. Apply a network policy to prevent connection between the 2

# 2.----------CIS Benchmark with Kube-bench
# Download the kube-bench Job YAML files.
wget -O kube-bench-control-plane.yaml https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-master.yaml
wget -O kube-bench-node.yaml https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job-node.yaml
# If you wish, you can examine the files to see what they do.
cat kube-bench-control-plane.yaml
cat kube-bench-node.yaml


# ---------- Control Plane listening Ports

K8s API Server 6443
etcd 2379-2380
Kubelet API 10250
kube-scheduler  10251
kube-controller-manager 10252
NodePort services 30000-32767

#=================Cluster Hardening==============
wget https://raw.githubusercontent.com/linuxacademy/content-cks-resources/main/S03L03-deployment-viewer-pod.yml
wget https://raw.githubusercontent.com/linuxacademy/content-cks-resources/main/S03L03-pod-viewer-pod.yml

role ---> rolebinding [NAMESPACE]
clusterrole ---> clusterrolebinding [CLUSTER]
clusterrole ---> rolebinding [NAMESPACE]


# Within the namespace "acme", grant the permissions in the "pod-reader" ClusterRole to a user named "bob":
kubectl create clusterrole pod-reader --verb=get,list,watch --resource=pods
kubectl create rolebinding bob-admin-binding --clusterrole=pod-reader --user=bob --namespace=acme
kubectl create rolebinding aws-sdk-binding --clusterrole=pod-reader --serviceaccount=auth:aws-sdk --namespace=auth


# ======System Hardening=======
apiVersion: v1
kind: Pod
metadata:
  name: host-namespaces
  namespace: auth
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
  hostIPC: true   # constainers will use host's inter-process communication namespace
  hostNetwork: true # constainers will use host's network namespace
  hostPID: true # constainers will use host's process ID namespace
  containers:
  - image: radial/busyboxplus:curl
    name: watcher
    command: ['sh', '-c', 'TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); while true; do if curl -s -o /dev/null -k -m 3 -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc.cluster.local/api/v1/namespaces/auth/pods/; then echo "[SUCCESS] Successfully viewed Pods!"; else echo "[FAIL] Failed to view Pods!"; fi; sleep 5; done']
    securityContext:
      allowPrivilegeEscalation: false
  serviceAccountName: aws-sdk
 
k describe po host-namespaces -n auth

```
apiVersion: v1
kind: Pod
metadata:
  name: host-namespaces
  namespace: auth
spec:
  containers:
  - image: radial/busyboxplus:curl
    name: watcher
    command: ['sh', '-c', 'TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); while true; do if curl -s -o /dev/null -k -m 3 -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc.cluster.local/api/v1/namespaces/auth/pods/; then echo "[SUCCESS] Successfully viewed Pods!"; else echo "[FAIL] Failed to view Pods!"; fi; sleep 5; done']
    securityContext:
      privileged: true
```

#============= AppArmor =============
A linux kernel security module
AppArmor is Mandatory Access Control (MAC) like security system for Linux. AppArmor confines individual programs to a set of files,
capabilities, network access and rlimits, collectively known as the AppArmor policy for the program, or simply as a profile. it can run in 2 modes

1. complain mode - only generate report of what the program is doing. `sudo apparmor_parser -C /path/to/profile`
2. enforce  mode - prevents the program from doing anything that the program does not allow. `sudo apparmor_parser /path/to/profile`

Profiles need to be loaded on the server where the pod will run or pod wont start

Use Pod annotations to apply an AppArmor profile to a container. For example:
`container.apparmor.security.beta.kubernetes.io/nginx: localhost/k8s-deny-write`


sudo vi /etc/apparmor.d/deny-write
---
#include <tunables/global>
profile deny-write flags=(attach_disconnected) {
#include <abstractions/base>
file,
# Deny all file writes.
deny /** w,
}
---
sudo apparmor_parser /etc/apparmor.d/deny-write

apiVersion: v1
kind: Pod
metadata:
  name: apparmor-disk-write
  annotations:
    container.apparmor.security.beta.kubernetes.io/busybox: localhost/deny-write
spec:
  containers:
  - name: busybox
    image: busybox
    command: ['sh', '-c', 'while true; do echo "I write to the disk!" > diskwrite.log; sleep 5; done']

kubectl create -f apparmor-disk-write-pod.yml --save-config


# ===== Pod Security Policy========
- to use Pod security policies, you first have to enable the PodSecurityPolicy admission controller
and you can do that using the --enable-admission-plugins flag on kube-apiserver.

- in order to create a Pod, a user or the Pod ServiceAccount must be authorized
to use a PodSecurityPolicy via the use verb in role-based access control.

- to apply a PodSecurityPolicy within the context of a specific namespace, you can authorize a ServiceAccount
in that namespace to utilize the policy.

# ===== OPA (Open Policy Agent) Gatekeeper=======
https://kubernetes.io/blog/2019/08/06/opa-gatekeeper-policy-and-governance-for-kubernetes/
allows you to enforce highly customizable policies on any kind of Kubernetes object at creation time.
Policies are defined using the Open Policy Access Constraint Framework.
Example: 
1. All deployment must have contact label listing the name of user who triggered the deployment 
2. All images must come from a specific repo 
3. All pod must specify resource limit

- Constraint Template
- Constraint

A Constraint Template defines a schema for a particular constraint and the Rego logic that will enforce that constraint.
So, this particular template allows you to pass in a set of labels as parameters. Templates use a language called Rego

A constraint is essentially an instance or an implementation of a Constraint Template.
So a constraint attaches the logic in that Constraint Template Rego to incoming Kubernetes objects
alongside any parameters that are defined in the Constraint Template.

# install
https://open-policy-agent.github.io/gatekeeper/website/docs/install/

kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/master/deploy/gatekeeper.yaml
or
helm repo add gatekeeper https://open-policy-agent.github.io/gatekeeper/charts
helm install gatekeeper/gatekeeper --name-template=gatekeeper --namespace gatekeeper-system --create-namespace

more templates https://github.com/open-policy-agent/gatekeeper/tree/master/demo/agilebank/templates


# ==== whitelisting Image repo ========

k apply -f k8sallowedrepos_template.yaml
k apply -f k8sallowedrepos_constraint.yaml
k apply -f pod_wrong_repo.yaml


 # ====Validating Image signatures ========
using the content of the image to sign the image
Get the diget from the image repo
DIGEST:sha256:2aeee51fe863dd23dc38a26e0b4389298a785aa45eb4831c347973474b7fe9a8
```
containers:
- name: busybox
  image: busybox:1.33.1@sha256:9687821b96b24fa15fac11d936c3a633ce1506d5471ebef02c349d85bebb11b5
  command: ['sh', '-c', 'echo "Hello, world!"']
```
# ========== Managing Secrets ==============

# create secret
echo -n 'admin' > ./username.txt
echo -n 'S!B\*d$zDsb=' > ./password.txt
# The -n flag ensures that the generated files do not have an extra newline character at the end of the text

kubectl create secret generic db-user-pass \
    --from-file=username=./username.txt \
    --from-file=password=./password.txt

# decode the secret
kubectl get secret db-user-pass -o jsonpath='{.data}'
echo 'UyFCXCpkJHpEc2I9' | base64 --decode

kubectl get secret db-user-pass -o jsonpath='{.data.password}' | base64 --decode


# ======== Container runtime sandboxes ========
Open Container Initiative - OCI

The main reason to use container runtime sandboxes is untrusted workloads.
use case
1. untrusted workloads
2. workloads that are relatively small and simple
3. workloads that don't need direct host access and won't mind the performance trade-offs of a container runtime sandbox
4. multi-tenant environments where you have others who have the ability to run workloads in your cluster
runtime sandboxes do potentially come at a performance cost

gVisor is a Linux application kernel that runs within the host operating system offering an additional layer of isolation
between the host operating system and the containers.

runsc is the OCI-compliant container runtime that actually integrates with gVisor and applications like Kubernetes.

Another way to implement a container runtime sandbox is to use Kata Containers.
Kata Containers provide an additional layer of isolation by transparently running containers inside lightweight virtual machines.



# --- signing certificate--------
https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/

# install cfssl
sudo apt-get install -y golang-cfssl

kg CertificateSigningRequest
NAME        AGE   SIGNERNAME                      REQUESTOR                                                  REQUESTEDDURATION   CONDITION
csr-nsb79   16m   kubernetes.io/kubelet-serving   system:node:ip-192-168-21-203.eu-west-1.compute.internal   <none>              Approved,Issued
csr-zk65f   18m   kubernetes.io/kubelet-serving   system:node:ip-192-168-35-192.eu-west-1.compute.internal   <none>              Approved,Issued

- create server key and csr 
- create kubectl csr 
- approve the csr

# how to create a TLS certificate for a Kubernetes service accessed through DNS.

k create ns cert-signing-demo
k run api --image=nginx -n cert-signing-demo
k expose pod api --port=80 --name=api-service-frontend --type NodePort --target-port 80 -n cert-signing-demo
kg all -n cert-signing-demo

service's cluster: IP 10.97.103.55
service's DNS: api-service-frontend.cert-signing-demo.svc.cluster.local 
pod's IP: 192.168.126.23
pod's DNS name: api.cert-signing-demo.pod.cluster.local 


cat <<EOF | cfssl genkey - | cfssljson -bare server
{
    "hosts": [
      "api-service-frontend.cert-signing-demo.svc.cluster.local",
      "api.cert-signing-demo.pod.cluster.local",
      "10.97.103.55",
      "192.168.126.23"
    ],
    "CN": "api.cert-signing-demo.pod.cluster.local",
    "key": {
      "algo": "ecdsa",
      "size": 256
    },
    "names": [
      {
        "O": "system:nodes"
      }
    ]
}
EOF

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: api-service-frontend.cert-signing-demo
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kubelet-serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: api-service-frontend.cert-signing-demo
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF

ubuntu@k8s-controller:~$ kg csr
NAME                                     AGE   SIGNERNAME                      REQUESTOR          REQUESTEDDURATION   CONDITION
api-service-frontend.cert-signing-demo   8s    kubernetes.io/kubelet-serving   kubernetes-admin   <none>              Pending

kubectl certificate approve api-service-frontend.cert-signing-demo

E0125 06:43:15.817265       1 authentication.go:63] "Unable to authenticate the request" err="invalid bearer token"
I0125 19:30:36.189299       1 trace.go:219] Trace[1131284394]: "Get" accept:application/vnd.kubernetes.protobuf, */*,audit-id:f4944303-1e58-4208-9b56-ff00bdc52b5f,client:10.192.10.22,protocol:HTTP/2.0,resource:leases,scope:resource,url:/apis/coordination.k8s.io/v1/namespaces/kube-system/leases/kube-controller-manager,user-agent:kube-controller-manager/v1.26.0 (linux/amd64) kubernetes/b46a3f8/leader-election,verb:GET (25-Jan-2023 19:30:35.502) (total time: 686ms):
Trace[1131284394]: ---"About to write a response" 686ms (19:30:36.189)
Trace[1131284394]: [686.576733ms] [686.576733ms] END
I0130 08:39:10.556743       1 alloc.go:327] "allocated clusterIPs" service="cert-signing-demo/api-service-frontend" clusterIPs=map[IPv4:10.97.103.55]


# ======== Supply Chain Security ========

# minimizing our base image attack surface
- make sure our images contain up-to-date software with the latest security patches
- minimize the amount of unnecessary software contained within your images
- get images from trusted sources. Attackers may purposefully create images that contain malicious software.
- 

# ======== Analyzing a Dockerfile ========
# static analysis of a dockerfile
- Avoid USER root (the final USER directive in the docker file)
- Avoid using latest:tag . Use are versioned tag
- Avoid unnecessary software
- No sensitive data 

# ======== Analyzing a YAML file ========
# static analysis of a YAML file 

- dont let containers use hostnamespaces (i.e hostIPC, hostNetwork, hostPID set to true)
- avoid privilege mode unless absolutely necesssary
- use fixed image tag. avoid latest
- avoid running as root or userid 0


for i in {1..5}; do
    echo "Welcome $i"   
done

k get node $node -o custom-columns=Count:.status.allocatable.pods

for node in $(kg nodes | awk '{print $1}' | awk 'NR!=1'); do echo Inspecting Node: $node;  echo 'Node running' $(k describe node $node | grep 'Non-terminated'); echo 'Allocatable pods:' $(k get node $node -o custom-columns=Count:.status.allocatable.pods); echo ''; done


# ============ Scanning Images for Known Vulnerabilities ========

Vulnerability scanning allows you to scan images to detect security vulnerabilities that have already been discovered and
documented by security researchers.
Trivy is a command-line tool that allows you to scan images by name and tag.
Scan an image name and tag with Trivy like so: trivy image busybox:1.33.1
In some cases, you may need to omit image like so: trivy nginx:1.14.1

https://github.com/aquasecurity/trivy
brew install trivy
docker run aquasec/trivy

docker run aquasec/trivy image myjenkins-blueocean:2.361.2-1

# ======== scanning images with an admission controller ========
Admission controllers intercept requests to the Kubernetes API and they can approve, deny, or modify the request before changes are actually made in the cluster.

# ImagePolicyWebhook controller
whenever you try to create a workload, like for example a Pod, it sends a request to an external webhook that contains information about the image that you are 
trying to use. And this external webhook can then approve or deny the creation of the workload based upon the image.
So essentially this ImagePolicyWebhook allows you to control which images are allowed to run in your cluster.

# setup
Use --enable-admission-plugins in the kube-apiserver manifest to enable the ImagePolicyWebhook admission
controller.
Use --admission-control-config-file to specify the location of the admission control configuration file.
If the config files are on the host file system, you may need to mount them to the kube-apiserver container.
In the admission control config, kubeConfigFile specifies the location of a kubeconfig file. This file tells
ImagePolicyWebhook how to reach the webhook backend.
In the admission control config, defaultAllow controls whether or not workloads will be allowed if the backend webhook
in unreachable.

sudo mkdir /etc/kubernetes/admission-control
sudo wget -O /etc/kubernetes/admission-control/imagepolicywebhook-ca.crt
https://raw.githubusercontent.com/linuxacademy/content-cks-trivy-k8s-webhook/main/certs/ca.crt
sudo wget -O /etc/kubernetes/admission-control/api-server-client.crt
https://raw.githubusercontent.com/linuxacademy/content-cks-trivy-k8s-webhook/main/certs/api-serverclient.crt
sudo wget -O /etc/kubernetes/admission-control/api-server-client.key
https://raw.githubusercontent.com/linuxacademy/content-cks-trivy-k8s-webhook/main/certs/api-serverclient.key
Create an admission control config file:
sudo vi /etc/kubernetes/admission-control/admission-control.conf


# ------concept of behavioral analytics-------
Falco is an open-source project created by Sysdig.
So Sysdig is basically the company that created Falco,
but Falco is open source,
and what Falco does is it monitors Linux system calls
at runtime and alerts on any suspicious activity based
on configurable rules.
https://falco.org/docs/

# install Falco on worker nodes
curl -s https://falco.org/repo/falcosecurity-3672BA8F.asc | sudo apt-key add -
echo "deb https://download.falco.org/packages/deb stable main" | sudo tee -a
/etc/apt/sources.list.d/falcosecurity.list
sudo apt-get update
sudo apt-get install -y falco

# create falco rules
vi falco-rules.yml
```
- rule: spawned_process_in_test_container
  desc: A process was spawned in the test container.
  condition: container.name = "falco-test" and evt.type = execve
  output: "%evt.time,%user.uid,%proc.name,%container.id,%container.name"
  priority: WARNING

```
# Run falco for 45 seconds using the rules file:
sudo falco -r falco-rules.yml -M 45

# View the list of Falco's supported fields:
sudo falco --list


# ------- Container Immutability -----
Immutability means that containers do not change at runtime (e.g., by downloading and running new code).
Containers that use privileged mode (i.e. securityContext.privileged: true ) may also be considered mutable.
Use container.securityContext.readOnlyRootFilesystem to prevent a container from writing to its file system.
If an application needs to write to files, such as for caching or logging, you can use an emptyDir volume alongside
readOnlyRootFilesystem .


# ---- Audit Logs ----------
Audit logs are a chronological record of actions performed through the Kubernetes API.
They are extremely useful for seeing what is going on in your cluster in real time.
That is, for threat detection or for examining what happened in the cluster after the fact, so in a post-mortem analysis.

None - which logs nothing,
RequestResponse - which logs everything, including the request and response body.
Request - logs only the request body, but not the response body.
Metadata - logs only the basic high-level metadata

```
# Log all requests at the Metadata level.
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
```

Define audit rules in the audit policy configuration file.
kube-apiserver flags for audit logging:
--audit-policy-file - Points to the audit policy config file.
--audit-log-path - The location of log output files.
--audit-log-maxage - The number of days to keep old log files.
--audit-log-maxbackup - The number of old log files to keep.

e.g.
```
- command:
- kube-apiserver
- --audit-policy-file=/etc/kubernetes/audit-policy.yaml
- --audit-log-path=/var/log/k8s-audit/k8s-audit.log
- --audit-log-maxage=30
- --audit-log-maxbackup=10


# Mount volumes to allow kube-apiserver to access the audit config and the audit log output directory:
volumes:
  - name: audit-config
  hostPath:
  path: /etc/kubernetes/audit-policy.yaml
  type: File
  - name: audit-log
  hostPath:
  path: /var/log/k8s-audit
  type: DirectoryOrCreate


volumeMounts:
  - name: audit-config
  mountPath: /etc/kubernetes/audit-policy.yaml
  readOnly: true
  - name: audit-log
  mountPath: /var/log/k8s-audit
  readOnly: false
```

# View the audit logs:
sudo tail -f /var/log/k8s-audit/k8s-audit.log


 

# kubeadm troubleshooting
sudo journalctl -f -b -u kubelet -o cat   
sudo journalctl -f -b -u kubelet

sudo service kubelet restart
sudo service kubelet status
sudo service kubelet restart; sudo journalctl -f -b -u kubelet -o cat 




# ----- Compilation of Kubernetes Security Tools
# Falco -  https://falco.org/docs/
it monitors Linux system calls at runtime and alerts on any suspicious activity based on configurable rules.


# Trivy https://github.com/aquasecurity/trivy
Trivy is a command-line tool that allows you to scan images by name and tag.


# OPA https://github.com/open-policy-agent/gatekeeper
to enforce highly customizable policies on any kind of Kubernetes object at creation time.
https://www.openpolicyagent.org/

# AppArmor https://apparmor.net/
AppArmor proactively protects the operating system and applications from external or internal threats, even zero-day attacks, by enforcing good behavior and preventing both known and unknown application flaws from being exploited.

#  Kube-bench https://github.com/aquasecurity/kube-bench
kube-bench is a popular open source CIS Kubernetes Benchmark assessment tool created by AquaSecurity. 
kube-bench is a Go application that checks whether Kubernetes is deployed securely by running the checks documented in the CIS Kubernetes Benchmark.
https://www.aquasec.com/cloud-native-academy/kubernetes-in-production/kubernetes-cis-benchmark-best-practices-in-brief/
https://archive.eksworkshop.com/intermediate/300_cis_eks_benchmark/


