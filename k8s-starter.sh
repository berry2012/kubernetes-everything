#!/bin/bash

# Before you start running k8s commands, you could aim for speed and simplicity

## Yaml file formatting with vim
echo 'set tabstop=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc

## create an alias
echo 'alias k=kubectl' >> ~/.bashrc
echo 'alias kg="kubectl get"' >> ~/.bashrc
echo 'alias kd="kubectl describe"' >> ~/.bashrc
echo 'export do="--dry-run=client -o yaml"' >> ~/.bashrc   
echo 'export now="--force --grace-period 0"' >> ~/.bashrc
echo 'alias c=clear' >> ~/.bashrc

source ~/.bashrc


## or apply to your present terminal
alias k=kubectl                         # will already be pre-configured
export do="--dry-run=client -o yaml"    # k get pod x $do
export now="--force --grace-period 0"   # k delete pod x $now


