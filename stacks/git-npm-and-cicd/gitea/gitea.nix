{ pkgs, lib, ... }:

let
  app = "giteaapp";
  socket = "/run/phpfpm/${app}.sock";
  domain = "localhost";
  url = "gitea.docker.localdev";
  title = "Gitea";
  admin_name = "admin";
  admin_password = "password";
  admin_email = "admin@docker.localdev";
  db_path = "/var/lib/gitea/data/gitea.db";

  giteaConfig = pkgs.writeTextFile {
    name = "app.ini";
    text = ''
      APP_NAME = Gitea: Git with a cup of tea
      RUN_MODE = prod

      [server]
      PROTOCOL = http
      DOMAIN = ${url}
      ROOT_URL = http://${url}/
      HTTP_ADDR = 127.0.0.1
      HTTP_PORT = 3000

      [database]
      DB_TYPE  = sqlite3
      HOST     = 127.0.0.1:3000
      NAME     = ${db_path}
      SSL_MODE = disable
      CHARSET  = utf8

      [repository]
      ROOT = /var/lib/gitea/repositories

      [mailer]
      ENABLED = false

      [service]
      DISABLE_REGISTRATION = false

      [session]
      PROVIDER_CONFIG = ${db_path}

      [security]
      INSTALL_LOCK   = true
      SECRET_KEY     = $(openssl rand -hex 16)
      INTERNAL_TOKEN = $(openssl rand -hex 16)
      COOKIE_USERNAME = $(openssl rand -hex 16)
      COOKIE_REMEMBER_NAME = $(openssl rand -hex 16)

      [oauth2]
      ENABLED = false

      [openid]
      ENABLED = false

      [logging]
      MODE      = console
      LEVEL     = Info
      COLOR     = true
      ROOT_PATH = /var/log/gitea
    '';
  };

in
{

  containers.gitea = {
    config = {
      services.gitea = {
        enable = true;
        package = pkgs.gitea;
        # config = {
        #   APP_NAME = title;
        #   RUN_MODE = "prod";
        #   ROOT_URL = "http://${url}/";
        #   HTTP_ADDR = "127.0.0.1";
        #   HTTP_PORT = 3000;
        #   SSH_DOMAIN = "gitea.docker.localdev";
        #   SSH_PORT = 222;
        #   SSH_LISTEN_PORT = 22;
        #   DB_TYPE = "sqlite3";
        #   DB_HOST = "127.0.0.1:3000";
        #   DB_NAME = db_path;
        #   DB_USER = "gitea";
        #   DB_PASSWD = "gitea";
        #   SERVICE_DISABLE_REGISTRATION = false;
        #   SECURITY_INSTALL_LOCK = true;
        #   # SECURITY_SECRET_KEY = lib.mkDefault (builtins.readFile "/dev/urandom" { count = 16; format = "hex"; });
        #   # SECURITY_INTERNAL_TOKEN = lib.mkDefault (builtins.readFile "/dev/urandom" { count = 16; format = "hex"; });
        #   # SECURITY_COOKIE_USERNAME = lib.mkDefault (builtins.readFile "/dev/urandom" { count = 16; format = "hex"; });
        #   # SECURITY_COOKIE_REMEMBER_NAME = lib.mkDefault (builtins.readFile "/dev/urandom" { count = 16; format = "hex"; });
        #   REPOSITORY_ROOT = "/var/lib/gitea/repositories";
        #   LOG_ROOT_PATH = "/var/log/gitea";
        # };
        # serviceConfig = {
        #   ExecStart = "${pkgs.gitea}/bin/gitea web --config ${giteaConfig}";
        #   User = "gitea";
        #   Restart = "on-failure";
        #   WorkingDirectory = "/var/lib/gitea";
        #   Environment = {
        #     HOME = "/var/lib/gitea";
        #   };
        #   ExecReload = "${pkgs.systemd}/bin/systemctl reload gitea.service";
        #   ExecStop = "${pkgs.systemd}/bin/systemctl stop gitea.service";
        #   ExecStopPost = "${pkgs.systemd}/bin/systemctl kill gitea.service";
        #   LimitNOFILE = 65535;
        # };
        # wantedBy = [ "multi-user.target" ];
      };

      users.mutableUsers = true;

      users.users.${app} = {
        isSystemUser = true;
        createHome = true;
        home = "/home/${app}";
        group = app;
      };
      users.groups.${app} = { };

      # Create directories for Gitea
      # systemd.tmpfiles.rules = [
      #   "d /var/lib/gitea/data 0750 ${app} ${app} -"
      #   "d /var/lib/gitea/custom 0750 ${app} ${app} -"
      #   "d /var/lib/gitea/indexers 0750 ${app} ${app} -"
      #   "d /var/lib/gitea/log 0750 ${app} ${app} -"
      #   "d /var/lib/gitea/public 0750 ${app} ${app} -"
      #   "d /var/lib/gitea/repositories 2770 ${app} ${app} -"
      #   "d /var/lib/gitea/templates 0750 ${app} ${app} -"
      # ];
      # users.extraGroups = [
      #   {
      #     name = "${app}";
      #     members = [ "${app}" ];
      #   }
      # ];
    };
  };
}
