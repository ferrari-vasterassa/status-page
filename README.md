# status-page
Load-balanced status page

Spins up 2 VMs behind a load balancer, poll DB for sample count in the last 5 minutes, returns:

-Error if DB is inaccessible
-Warning if less than 4 samples
-Warning if average of last 5 minutes' samples less than 46
-OK otherwise

Responds on http://<lb ip>/monitor

DB records a random value between 0 and 99 every minute.


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

