#!/bin/bash

# Before you start running k8s commands, you could aim for speed and simplicity

## create an alias
echo 'alias k=kubectl' >>~/.bashrc
source ~/.bashrc



alias k=kubectl                         # will already be pre-configured
export do="--dry-run=client -o yaml"    # k get pod x $do
export now="--force --grace-period 0"   # k delete pod x $now

echo 'set tabstop=2' >> ~/.vimrc
echo 'set expandtab' >> ~/.vimrc
echo 'set shiftwidth=2' >> ~/.vimrc
