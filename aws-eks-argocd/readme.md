# GitOps on Amazon EKS with ArgoCD


## Install ArgoCD

```
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.5/manifests/install.yaml
```

## Use ingress to expose argoCD

```
kubectl apply argocd-ingress.yaml

ARGOCD_SERVER=argocd.myinstance.com

echo "ArgoCD URL: https://$ARGOCD_SERVER"
```

## Retrieve Cred
```
export ARGO_PWD=`kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
echo $ARGO_PWD
```

## Install argoCD client

```
sudo curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.8.5/argocd-linux-amd64
sudo chmod +x /usr/local/bin/argocd

# on macos
brew install argocd
```

## login

```
argocd login $ARGOCD_SERVER --username admin --password $ARGO_PWD --insecure
```

## Connect with ArgoCD CLI using our cluster context:

```
CONTEXT_NAME=`kubectl config view -o jsonpath='{.current-context}'`
argocd cluster add $CONTEXT_NAME
```

## Rollout Application Deployment

```
kubectl create namespace argoeks
argocd app create reactjswebapp --repo https://github.com/berry2012/kubernetes-everything.git --path aws-eks-argocd/workload --dest-server https://kubernetes.default.svc --dest-namespace argoeks
argocd app get reactjswebapp
argocd app sync reactjswebapp
```