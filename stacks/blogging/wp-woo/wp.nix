{ pkgs, lib, config, ... }:
let
  app = "wpdemo";
  socket = "/run/phpfpm/${app}.sock";
  domain = "localhost";
  url = "wp.docker.localdev";
  title = "wpdemo";
  admin_name = "admin";
  admin_password = "password";
  admin_email = "admin@docker.localdev";

  wpConfig = pkgs.writeTextFile {
    name = "wp-config.php";
    text = ''
      <?php
       define( 'DB_NAME', 'wordpress' );
       define( 'DB_USER', 'admin' );
       define( 'DB_PASSWORD', 'password' );
       define( 'DB_HOST', 'localhost:3308' );
       define( 'DB_CHARSET', 'utf8mb4' );
       define( 'DB_COLLATE', "" );
       define( 'AUTH_KEY',         ':~^sR[>1.(V+xUVlb=ZhFe0}CLX7_$GRUZ~N`bJ~CV:y.9_QzLXSR>@naB@MCxlE' );
       define( 'SECURE_AUTH_KEY',  'lHPJiO<5Xu?#04]l *B#OXRk|5L>!{$,[Q3|d:5Zvs2<2l8cpfSqJME^h9< dlKs' );
       define( 'LOGGED_IN_KEY',    '9=^oA8+arx}0x-VT-x;cDYYjnUG&`LZ[uNFZ7xqW?O>nqV:%k`K|bGp?uxya1nMN' );
       define( 'NONCE_KEY',        ',RkuN!9y%j8&@FC[$]&Q!Z @8+mNh_CW)(-BJb.;~7#RY.eldil]+L94fR%A@7yj' );
       define( 'AUTH_SALT',        'IRgQaeXs0=MA^xnBZhH.h+p~Tt C#tFO.!4ngHm-SACe6JW(5ryH_G8^jmKzi#E)' );
       define( 'SECURE_AUTH_SALT', 'E=K_tHI{Y5dHy32gMWk&T>}fk28M+?z- vPjM7pMK$9&Dc!NMkWHlI-0|~ieaSC<' );
       define( 'LOGGED_IN_SALT',   'z3R/4ym(I6K*Gn1 6e6Ee,=p3k>W%df)Vl^,xQ0>.9-u88M|ZL|HC_-F+Ib;uOEX' );
       define( 'NONCE_SALT',       '^,mDQrt@`O#m~RJ4YiMqM]~_L^[:^`8A7_ u)NUUG8i?tH?dFW.ik#j--cu?G&bu' );
       $table_prefix = 'wp_';

       define( 'WP_DEBUG', false );

       if ( ! defined( 'ABSPATH' ) ) {
       	define( 'ABSPATH', __DIR__ . '/' );
       }
       require_once ABSPATH . 'wp-settings.php';

               
    '';
  };




in
{
  containers.wp = {


    config = {
      networking.firewall.enable = false;
      security.acme.defaults.email = "admin@docker.localdev";
      networking.firewall.allowedTCPPorts = [ 80 82 ];
      services.traefik = {
        enable = true;
        staticConfigOptions = {
          providers.docker = {
            exposedByDefault = false;
          };
          entryPoints.web.address = ":80";
        };
        dynamicConfigOptions = {
          http.routers.wp = {
            rule = "Host(`wp.docker.localdev`)";
            entryPoints = [ "web" ];
            service = "wp-service";
          };
          http.services.wp-service.loadBalancer.server.port = 80;
        };
      };

      services.phpfpm.pools.${app} = {
        user = app;
        settings = {
          "listen.owner" = "nginx";
          "pm" = "dynamic";
          "pm.max_children" = 32;
          "pm.max_requests" = 500;
          "pm.start_servers" = 2;
          "pm.min_spare_servers" = 2;
          "pm.max_spare_servers" = 5;
          "php_admin_value[error_log]" = "stderr";
          "php_admin_flag[log_errors]" = true;
          "catch_workers_output" = true;
        };
        phpEnv."PATH" = lib.makeBinPath [ pkgs.php ];
      };

      services.mysql = {
        enable = true;
        package = pkgs.mariadb;
        settings = {
          "mysqld" = {
            "port" = 3308;
          };
        };
        initialScript =
          pkgs.writeText "initial-script" ''
            CREATE DATABASE IF NOT EXISTS wordpress;
            CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'password';
            GRANT ALL PRIVILEGES ON wordpress.* TO 'admin'@'localhost';
          '';

        ensureDatabases = [
          "wordpress"
        ];
        ensureUsers = [
          {
            name = "admin";
            ensurePermissions = {
              "admin.*" = "ALL PRIVILEGES";
              "*.*" = "ALL PRIVILEGES";
            };
          }
        ];
      };

      #  wp db import <file>
      #  echo "${wpDbFile}" | "${pkgs.wp-cli}/bin/wp" db import - --allow-root

      systemd.services.wordpress.serviceConfig = {
        ProtectSystem = lib.mkForce false;
        ProtectHome = lib.mkForce false;
        ReadWritePaths = [ "/var" "/home" "/home/www" ];
      };


      systemd.services.wpsetup = {
        path = with pkgs; [ coreutils wget gzip curl unzip rsync wp-cli php ];
        wantedBy = [ "multi-user.target" ];
        script = ''
         
        mkdir -p /var/www/wpdemo

         cd  /var/www/wpdemo  
          # echo  "${pkgs.wp-cli}/bin/wp" > a.txt
        "${pkgs.wp-cli}/bin/wp" core download --allow-root --locale=en_US --path=/var/www/wpdemo/
         ln -s ${wpConfig} /var/www/wpdemo/wp-config.php
        "${pkgs.wp-cli}/bin/wp" core install --allow-root \
        --url="${url}" \
        --title="${title}" \
        --admin_name="${admin_name}" \
        --admin_password="${admin_password}" \
        --admin_email="${admin_email}"

        "${pkgs.wp-cli}/bin/wp" plugin install  --allow-root woocommerce woocommerce-payments woocommerce-services meta-box --activate
        "${pkgs.wp-cli}/bin/wp" theme install  --allow-root storefront   --activate

  

      chmod 777 -R /var/www/wpdemo  


      cd /var/www/wpdemo/wp-content/themes/storefront/
      sed -i '$a require_once '"'custom-inc.php'"';' functions.php

      cd /var/www/wpdemo/

      curl -L https://codeload.github.com/protob/nix___stacks/zip/refs/heads/main -o stacks.zip
      unzip stacks.zip
      cp nix___stacks-main/stacks/blogging/wp-woo/extras/custom-inc.php /var/www/wpdemo/wp-content/themes/storefront/custom-inc.php 
      cp nix___stacks-main/stacks/blogging/wp-woo/extras/wp-db.sql .

      "${pkgs.wp-cli}/bin/wp" db import  wp-db.sql  --allow-root 

        '';
        serviceConfig = {


          ProtectSystem = lib.mkForce false;
          ProtectHome = lib.mkForce false;
          ReadWritePaths = [ "/var" "/home" "/home/wpdemo" "/home/wpdemo/www" ];

          # PATH = "${pkgs.php}/bin:services.phpfpm.pools.wpdemo.phpEnv.PATH}";
          # PATH = "${pkgs.php}/bin:config.systemd.services.wpsetup.phpEnv.PATH";

        };
      };

      systemd.services.ngnix.serviceConfig = {

        ProtectSystem = lib.mkForce false;
        ProtectHome = lib.mkForce false;
        ReadWritePaths = [ "/var" "/home" "/home/wpdemo" "/home/wpdemo/www" ];
      };
      services.nginx = {
        enable = true;

        virtualHosts.${domain} = {
          listen = [{
            addr = "127.0.0.1";
            port = 80;
          }];
          serverName = "wp.docker.localdev";

          locations."/" = {
            root = "/var/www/wpdemo";
            extraConfig = ''
              access_log off;
              charset utf-8;
              etag off;
              index index.php;
 
                location / {
                  try_files $uri/index.html $uri $uri/ /index.php?$query_string;
                }

              location ~ \.php$ {
                  fastcgi_split_path_info ^(.+\.php)(/.+)$;
                  fastcgi_pass  unix:${socket};
                  include ${pkgs.nginx}/conf/fastcgi_params;
                  include ${pkgs.nginx}/conf/fastcgi.conf;
                  
               

              }
            '';
          };
        };
      };

      users.mutableUsers = true;

      users.users.${app} = {
        isSystemUser = true;
        createHome = true;
        home = "/home/wpdemo";
        group = app;
      };
      users.groups.${app} = { };
    };
    # bindMounts = {
    #   "/var/www/wpdemo/wp-content/themes" = {
    #     hostPath = "/var/www/wpdemo/wp-content/themes/";
    #     isReadOnly = false;
    #   };
    # };
  };


  environment.systemPackages = with pkgs; [
    wget
    gzip
    unzip
    git
    vim
    wp-cli
    php
  ];
}


