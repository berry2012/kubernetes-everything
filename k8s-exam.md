

## CKA

- https://kubernetes.io/docs
- https://github.com/kubernetes
- https://kubernetes.io/blog

## CKA Playground

- https://killercoda.com/killer-shell-cka


## CKS 

- https://kubernetes.io/docs
- https://github.com/kubernetes
- https://kubernetes.io/blog
- https://aquasecurity.github.io/trivy
- https://falco.org/docs
- https://gitlab.com/apparmor/apparmor/-/wikis/Documentation

## CKS Goals

- Be comfortable with changing the kube-apiserver in a kubeadm setup
- Be able to work with AdmissionControllers
- Know how to create and use the ImagePolicyWebhook
- Know how to use opensource tools Falco, Sysdig, Tracee, Trivy

## CKS Scenario Playground

- https://killercoda.com/killer-shell-cks


# Know your VIM

## how to tab multiple line in vim

- To indent multiple lines using vim you should set the shiftwidth using `:set shiftwidth=2`. Then mark multiple lines using Shift v and the up/down keys.

- To then indent the marked lines press > or < and to repeat the action press .


## comment multiple lines with vim

- goto start of line
- press Ctrl + v
- move arrow to end of file
- press Shift + i  to INSERT
- press # for comment
- esc
or
```
: s/^/# [press enter]
```

## uncomment multiple lines with vim

- goto start of line
- press Ctrl + v
- move arrow to end of file
- press d for uncomment
- esc


## vim undo
Press u, :u, or :undo to undo the last change (entry)

## Indent multiple lines

To indent multiple lines press Esc and type :set shiftwidth=2. First mark multiple lines using Shift v and the up/down keys. Then to indent the marked lines press > or <. You can then press . to repeat the action.



## vim copy and paste

- Mark lines: Esc+V (then arrow keys)
- Copy marked lines: y
- Cut marked lines: d
- Past lines: p or P


## open file with gedit
gedit dep.yaml




## APIs in different k8s version 1.23

```
kubectl-convert 
kubectl diff
```


## Best Shortcuts for speed

Shell Profile
```
vim ~/.bashrc

export do="--dry-run=client -o yaml"
export now="--force --grace-period=0"
alias k=kubectl
alias c=clear
alias kg="kubectl get"
alias kd="kubectl describe"
alias ke="kubectl edit"
alias ka="kubectl apply -f"
alias kn='kubectl config set-context --current --namespace'
```

VIM
```
vim ~/.vimrc
set expandtab
set shiftwidth=2
set tabstop=2
set autoindent
set smartindent
set bg=dark
set nowrap
set paste
```


## Troubleshooting API Server


**Log locations to check:**
```
/var/log/pods
/var/log/containers

# kubelet logs: 
/var/log/syslog or journalctl or /var/log/messages
```

```
crictl ps + crictl logs
docker ps + docker logs (in case when Docker is used)

# wait till container restarts
watch crictl ps
```

