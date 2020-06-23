# status-page
Load-balanced status page

Spins up 2 VMs behind a load balancer

Use:

```shell
$ cp env.sh.template env.sh
$ chmod u+x env.sh
-edit env.sh, choose AZ region

$ source env.sh
$ terraform init
$ terraform plan
$ terraform apply
```

