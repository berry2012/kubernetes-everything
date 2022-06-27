
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

k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl 10.44.0.78
k run tmp --restart=Never --rm -i --image=nginx:alpine -- curl -m 5 jupiter-crew-svc:8080
k run tmp --restart=Never --rm -it --image=nginx:alpine -- curl -m 5 jupiter-crew-svc:8080
k run tmp --restart=Never --rm -i --image=busybox -i -- wget -O- frontend:80

# jobs
k -n delta create job api-job --image=busybox:1.31.0 $do -- sh -c "sleep 2 && echo done" > job.yaml

# label
k -n sun label pod -l "type in (worker,runner)" protected=true
k -n sun annotate pod -l protected=true protected="do not delete this pod"