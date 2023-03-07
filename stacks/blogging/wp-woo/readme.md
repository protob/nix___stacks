TODO:
currently wp cli import is not working declative container config

```
${pkgs.wp-cli}/bin/wp" db import  wp-db.sql  --allow-root 
```
To apply import

```
sudo extra-container create --start <<EOF
$(cat wp.nix)
EOF
```

```
sudo nixos-container root-login wp
cd /var/www/wpdemo
/nix/store/dswy26xs8nh2q3w3nizxvj94zk7djl2r-wp-cli-2.6.0/bin/wp db import  wp-db.sql  --allow-root 

````

http://wp.docker.localdev/wp-admin
user:admin
pw:password


