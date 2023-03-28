
# To make vim use 2 spaces for a tab edit ~/.vimrc to contain:
set tabstop=2
set expandtab
set shiftwidth=2


# Example - how to tab multiple line in vim
To indent multiple lines using vim you should set the shiftwidth using `:set shiftwidth=2`. Then mark multiple lines using Shift v and the up/down keys.
To then indent the marked lines press > or < and to repeat the action press .

# nice to have shortcuts
alias c=clear                           # will clear screen
alias k=kubectl                         # shortcut
export do="--dry-run=client -o yaml"    # k get pod x $do
export now="--force --grace-period 0"   # k delete pod x $now


# example kubectl commands

# pods
k run pod_with_command --image=busybox:1.31.0 $do --command -- sh -c "touch /tmp/ready && sleep 1d" > pod_with_command.yaml
k -n beta run map-api --image=nginx:1.17.3-alpine --labels map-api
k run nginx --image=nginx --restart=Never --port=80 --expose
k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl 10.44.0.78
k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 jupiter-crew-svc:8080
k run tmp --restart=Never --rm -it --image=nginx:alpine -- curl -m 5 jupiter-crew-svc:8080
k run tmp --restart=Never --rm -i --image=busybox -i -- wget -O- frontend:80
k run tmp --image=busybox $do --requests=memory=20Mi --limits=memory=50Mi


# jobs
k -n delta create job api-job --image=busybox:1.31.0 $do -- sh -c "sleep 2 && echo done" > job.yaml

# label
k -n sun label pod -l "type in (worker,runner)" protected=true
k -n sun annotate pod -l protected=true protected="do not delete this pod"

# convert ClusterIP service to NodePort
kubectl patch svc nginx -p '{"spec":{"type":"NodePort"}}' 

# For example, to convert an older Deployment to apps/v1, you can run:
kubectl-convert -f ./my-deployment.yaml --output-version apps/v1

# comparing planned deployment with what is in cluster
kubectl diff -f ./manifest-old.yaml


# remove finalizers from some pods 
for pod in $(kg po | grep load | awk '{print $1}'); 
do 
  echo patching pod: $pod; 
  kubectl patch pod/$pod \
      --type json \
      --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]'
done


# --------------Amazon EKS ------------------
# Get nodes with AZ and instance type
kubectl get nodes -L topology.kubernetes.io/zone,node.kubernetes.io/instance-type

# Get instance ID as extra column
kubectl get nodes -o custom-columns=Name:.metadata.name,Instance:.spec.providerID

# Get the current running pods on nodes and the maximum allocatable pods the node can run
for node in $(kg nodes | awk '{print $1}' | awk 'NR!=1'); do echo Inspecting Node: $node;  echo 'Node running' $(k describe node $node | grep 'Non-terminated'); echo 'Allocatable pods:' $(k get node $node -o custom-columns=Count:.status.allocatable.pods); echo ''; done




