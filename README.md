# status-page
Status page for widget monitoring db

Use:

```shell
$ cp env.sh.template env.sh
$ chmod u+x env.sh
-edit env.sh, choose AZ region, set Cloudflare access tokens, Cloudflare domain zone filter

$ source env.sh
$ terraform init
$ terraform plan
$ terraform apply
```

