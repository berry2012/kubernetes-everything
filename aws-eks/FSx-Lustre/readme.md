# Mounting FSx Lustre to Worker Nodes using HostPath

1. Create the AWS FSx Lustre  
2. Run the commands to mount to your AWS EKS Worker Nodes
```
sudo amazon-linux-extras install -y lustre2.10
sudo mkdir /fsx
sudo mount -t lustre -o noatime,flock fs-XXXXXXXXXXXXXXX.fsx.eu-west-1.amazonaws.com@tcp:/exv6lbmv /fsx
```
3. Deploy your Cronjob

```
kubectl create -f manifest.yml
```

4. Verify the cronjob

```
─[$] <> kg cronjob.batch/fsxlustremount -w
NAME             SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
fsxlustremount   */2 * * * *   False     0        <none>          11s
fsxlustremount   */2 * * * *   False     1        0s              118s
fsxlustremount   */2 * * * *   False     0        4s              2m2s
fsxlustremount   */2 * * * *   False     0        4s              2m2s

```
5. Verify that Pod was created based on the schedule
```
└─[$] <> kg pods -w                             
NAME                          READY   STATUS    RESTARTS   AGE
fsxlustremount-27837136-4plvp   0/1     Pending   0          0s
fsxlustremount-27837136-4plvp   0/1     Pending   0          0s
fsxlustremount-27837136-4plvp   0/1     ContainerCreating   0          0s
fsxlustremount-27837136-4plvp   0/1     Completed           0          2s
fsxlustremount-27837136-4plvp   0/1     Completed           0          4s
```

6. Verify the content of the FSx Lustre from available worker nodes

```
└─[$] <> kubectl get nodes
NAME                                            STATUS   ROLES    AGE   VERSION
ip-192-168-73-194.eu-west-1.compute.internal    Ready    <none>   17m   v1.23.9-eks-ba74326
ip-192-168-99-87.eu-west-1.compute.internal     Ready    <none>   57m   v1.23.13-eks-fb459a0

[root@ip-192-168-99-87 ~]# tail -f /fsx/success.txt 
Hello from the Kubernetes cluster
Mon Dec 5 08:16:01 UTC 2022 - Hello from the Kubernetes cluster

[root@ip-192-168-73-194 ~]# tail -f /fsx/success.txt
Hello from the Kubernetes cluster
Mon Dec 5 08:16:01 UTC 2022 - Hello from the Kubernetes cluster

```
