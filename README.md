This terraform code is for deploying kubernetes master node and worker node.
In this code whole kubernetes installation and setup are there. 
In this code you only need to add your access key and secret key of your aws credentials.
This code is incomplete because when you want to connect worker node with master node you need a kubeadm-join-command from master node and take that command in worker node. So you only need to do one step to connect master to worker that run "kubeadm token create --print-join-command" command in master node and then copy the output and paste it in worker node.
Above step only works when both master and worker both the nodes are created.
