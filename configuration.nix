# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/7449971a3ecf857b4a554cf79b1d9dcc1a4647d8.tar.gz"), ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>
      ((import ./nix/sources.nix).arion + "/nixos-module.nix")
    ];

  hardware.opengl.driSupport32Bit = true;
  hardware.nvidia.prime.offload.enable = true;

  boot = {
    kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi";
    };
    #zfs.extraPools = [ "glacier" "weasel" ];
    initrd = {
      secrets = {
        "/crypto_keyfile.bin" = null;
      };
      luks.devices."luks-a3473720-33ae-47ec-949f-f1167778cc6" = {
        device = "/dev/disk/by-uuid/a3473720-33ae-47ec-949f-f116e7778cc6";
        keyFile = "/crypto_keyfile.bin";
      };
    };
  };

  networking = {
    hostName = "snowglobe";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowPing = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedTCPPorts = [ 50 80 81 443 5357 ];
      allowedUDPPorts = [ config.services.tailscale.port 3702 ];
      checkReversePath = "loose";
    };
  };
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_IE.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_IE.UTF-8";
    LC_IDENTIFICATION = "en_IE.UTF-8";
    LC_MEASUREMENT = "en_IE.UTF-8";
    LC_MONETARY = "en_IE.UTF-8";
    LC_NAME = "en_IE.UTF-8";
    LC_NUMERIC = "en_IE.UTF-8";
    LC_PAPER = "en_IE.UTF-8";
    LC_TELEPHONE = "en_IE.UTF-8";
    LC_TIME = "en_IE.UTF-8";
  };

  # List services that you want to enable:
  services = {
    xserver = {
      enable = true;
      displayManager.sddm.enable = true;
      desktopManager.plasma5.enable = true;
      layout = "us";
      xkbVariant = "";
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    openssh = {
      enable = true;
      ports = [ 50 ];
    };
    tailscale.enable = true;
    zfs = {
      autoScrub.enable = true;
      trim.enable = true;
    };
    samba-wsdd.enable = true;
    samba = {
      enable = true;
      openFirewall = true;
      securityType = "user";
      extraConfig = ''
        hosts allow = 192.168.0 127.0.0.1 localhost
        hosts deny = 0.0.0.0/0
        guest account = nobody
        map to guest = bad user
      '';
      shares = {
        weasel = {
          path = "/mnt/weasel";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "644";
          "directory mask" = "0755";
        };
        glacier = {
          path = "/mnt/glacier";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "yes";
          "create mask" = "0664";
          "directory mask" = "0755";
        };
      };
    };
  };

   programs.gnupg.agent = {
     enable = true;
     enableSSHSupport = true;
   };

  systemd.services = {
    tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
      after = [ "network-pre.target" "tailscale.service" ];
      wants = [ "network-pre.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = 
      let 
        tailscalecli = "${pkgs.tailscale}/bin/tailscale"; 
        jqcli = "${pkgs.jq}/bin/jq";
      in ''
        sleep 2
        status="$(${tailscalecli} status -json | ${jqcli} -r .BackendState)"

        if [ $status = "Running" ]; then exit 0; fi;

        #${tailscalecli} up -authkey authkeyhere
      '';
    };
  };

  virtualisation = {
    containers.registries.search = [ "docker.io" "quay.io" "ghcr.io" "lscr.io" ];
    docker = {
      enable = true;
#      storageDriver = "zfs";
      enableNvidia = true;
      enableOnBoot = true;
#      autoPrune.enable = true;
#      liveRestore = false;
    };
    arion = {
      backend = "docker";
      projects = {
        reverse-proxy.settings = {
          services = {
            proxyManager.service = {
              restart = "unless-stopped";
              image = "jc21/nginx-proxy-manager:2.9.19";
              ports = [
                "80:80"
                "443:443"
              ];
              volumes = [
                "/services/reverseProxy/data:/data"
                "/services/reverseProxy/letsencrypt:/etc/letsencrypt"
              ];
            };

            homepage.service = {
              restart = "unless-stopped";
              image = "pawelmalak/flame:2.3.0";
              volumes = [ "/services/flame/data:/app/data" ];
              environment.PASSWORD="homepageSetup";
            };
          };
          networks.primary = {
            name = "internalLoopback";
            ipam = {
              config = [{ "subnet"="172.20.0.0/16"; }];
            };
          };
        };

        media-management.settings = {
          services = {
            mullvad.service = {
              restart = "unless-stopped";
              image = "haugene/transmission-openvpn:5.0";
              environment = {
                OPENVPN_PROVIDER = "MULLVAD";
                OPENVPN_USERNAME = "5189266622301285";
                OPENVPN_PASSWORD = "m";
                OPENVPN_CONFIG = "gb_all";
                LOCAL_NETWORK = "172.20.0.0/24";
              };
              ports = [
                "9091:9091"
                "8090:8090"
                "6881:6881"
                "6881:6881/udp"
              ];
              sysctls = {
                "net.ipv6.conf.all.disable_ipv6" = "0";
              };
              capabilities.NET_ADMIN = true;
            };
            qbt.service = {
              depends_on = [ "mullvad" ];
              restart = "unless-stopped";
              image = "linuxserver/qbittorrent:4.5.2";
              environment = {
                TZ="America/New_York";
                UMASK_SET="022";
                WEBUI_PORT="8090";
              };
              volumes = [
                "/services/qbt/config:/config"
                "/mnt/glacier/torrentSync/tempFolder:/downloads"
                "/mnt/glacier/torrentSync/sonarrParsing:/tvdownloads"
                "/mnt/glacier/torrentSync/radarrParsing:/filmdownloads"
              ];
              network_mode = "service:mullvad";
            };

            indexers.service = {
              depends_on = [ "qbt" ];
              restart = "unless-stopped";
              image = "linuxserver/prowlarr:1.4.0-develop";
              environment.TZ="America/New_York";
              volumes = [ "/services/prowlarr/config:/config"];
            };

            movies.service = {
              depends_on = [ "indexers" ];
              restart = "unless-stopped";
              image = "linuxserver/radarr:4.4.4";
              environment.TZ="America/New_York";
              volumes = [
                "/etc/localtime:/etc/localtime:ro"
                "/services/radarr/config:/config"
                "/mnt/glacier/Movies:/media"
                "/mnt/glacier/torrentSync/radarrParsing:/mnt/downloads"
              ];
            };

            tv.service = {
              depends_on = [ "indexers" ];
              restart = "unless-stopped";
              image = "linuxserver/sonarr:3.0.10";
              environment.TZ="America/New_York";
              volumes = [
                "/etc/localtime:/etc/localtime:ro"
                "/services/sonarr/config:/config"
                "/mnt/glacier/TV:/media"
                "/mnt/glacier/torrentSync/sonarrParsing:/mnt/downloads"
              ];
            };

            transcode.service = {
              image = "haveagitgat/tdarr:2.00.20.1";
              environment = {
                UMASK_SET="002";
                TZ="America/New_York";
                NVIDIA_VISIBLE_DEVICES="all";
                internalNode="true";
                webUIPort="8265";
                serverPort="8266";
                serverIP="0.0.0.0";
              };
              ports = [ "8266:8266" ];
              volumes = [
                "/services/tdarr/server:/app/server"
                "/services/tdarr/configs:/app/configs"
                "/services/tdarr/logs:/app/logs"
                "/services/tdarr/cache:/temp"
                "/mnt/glacier/Movies:/movies"
                "/mnt/glacier/TV:/tv"
                "/mnt/glacier/TV-Gundam:/tv-gundam"
              ];
            };

            subtitles.service = {
              image = "linuxserver/bazarr:1.2.0";
              environment.TZ="America/New_York";
              volumes = [
                "/etc/localtime:/etc/localtime:ro"
                "/services/bazarr/config:/config"
                "/mnt/glacier/Movies:/movies"
                "/mnt/glacier/TV:/tv"
              ];
            };
          };
          networks.primary = {
            name = "internalLoopback";
            ipam = {
              config = [{ "subnet"="172.20.0.0/16"; }];
            };
          };
        };

        public-facing.settings = {
          services = {
            carInfo.service = {
              image = "akhilrex/hammond:1.0.0";
              volumes = [
                "/services/carInfo/config:/config"
                "/services/carInfo/assets:/assets"
              ];
            };

            jellyfin.service = {
              image = "jellyfin/jellyfin:10.8.10";
              volumes = [
                "/services/jellyfin/config:/config"
                "/services/jellyfin/cache:/cache"
                "/mnt/glacier/Movies:/movies"
                "/mnt/glacier/TV:/tv"
                "/mnt/glacier/TV-Gundam:/tv-Gundam"
              ];
              environment.NVIDIA_VISIBLE_DEVICES="all";
              #runtime = "nvidia";
            };
            nextcloud.service = {
              depends_on = [ "nextcloud_db" ];
              image = "nextcloud:26.0.1";
              environment = {
                MYSQL_PASSWORD="nextcloudPassword";
                MYSQL_DATABASE="nextcloud";
                MYSQL_USER="nextcloud";
                MYSQL_HOST="localhost";
              };
            };
            nextcloud_db.service = {
              image = "mariadb:10.11.2";
              volumes = [ "/services/nextcloud_db/db:/var/lib/mysql" ];
              environment = {
                MYSQL_ROOT_PASSWORD="extraspecialsecretpassword";
                MYSQL_PASSWORD="nextcloudPassword";
                MYSQL_DATABASE="nextcloud";
                MYSQL_USER="nextcloud";
              };
            };
            wekan.service = {
              depends_on = [ "wekan_db" ];
              image =  "wekanteam/wekan:v6.86";
              volumes = [
                "/etc/localtime:/etc/localtime:ro"
                "/services/wekan/data:/data"
              ];
              environment = {
                WRITABLE_PATH="/data";
                MONGO_URL="mongodb://localhost:27017/wekan";
                ROOT_URL="https://wekan.blizzard.systems";
                WITH_API="true";
                RICHER_CARD_COMMENT_EDITOR="true";
                CARD_OPENED_WEBHOOK_ENABLED="false";
                BIGEVENTS_PATTERN="NONE";
                BROWSER_POLICY_ENABLED="true";
              };
            };
            wekan_db.service = {
              image = "mongo:5.0.17";
              volumes = [
                "/etc/localtime:/etc/localtime:ro"
                #"/etc/timezone:/etc/timezone:ro"
                "/services/wekan_db/db:/data/db"
                "/services/wekan_db/dump:/dump"
              ];
            };
            kanboard.service = {
              image = "kanboard/kanboard:v1.2.27";
              environment.PLUGIN_INSTALLER="true";
              volumes = [
                "/services/kanboard/data:/var/www/app/data"
                "/services/kanboard/plugins:/var/www/app/plugins"
              ];
            };
            n8n.service = {
              image = "n8nio/n8n:0.226.0";
              environment = {
                GENERIC_TIMEZONE="America/New_York";
                TZ="America/New_York";
              };
              volumes = [ "/services/n8n/data:/home/node/.n8n" ];
            };
          };
          networks.primary = {
            name = "internalLoopback";
            ipam = {
              config = [{ "subnet"="172.20.0.0/16"; }];
            };
          };
        };
      };
    };
  };

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users = {
    bluestar = {
      isNormalUser = true;
      shell = pkgs.zsh;
      description = "Blizzard Finnegan";
      extraGroups = [ "networkmanager" "wheel" ];
    };
    jellyfin = {
      uid = 998;
      group = "jellyfin";
      isNormalUser = true;
      extraGroups = [ "video" "render" ];
    };
  };
  users.groups.jellyfin.gid = 997;

  # Home-manager stuff:
  home-manager.users.bluestar = {pkgs, config, ... }: {
  	home = {
		packages = with pkgs; [
      			firefox
			maven
			links2
			gnupg
			openssh
			jdk11
			rsync
			vifm
      			btop
      			jellyfin-media-player
      			texlive.combined.scheme-full
      			zsh
      			git
      			tmux
			exa
		];
	};
	manual = {
		json.enable = true;
		manpages.enable = true;
	};
	programs = {
		command-not-found.enable = true;
		ssh = {
			enable = true;
			hashKnownHosts = true;
			matchBlocks = {
				"github" = {
					hostname = "github.com";
					user = "git";
					#identityFile = "/home/bluestar/.ssh/github";
				};
				"gitlab" = {
					hostname = "gitlab.com";
					user = "git";
					#identityFile = "/home/bluestar/.ssh/gitlab";
				};
				"mediaTV" = {
					hostname = "192.168.0.100";
					user = "ashstar";
					port = 50;
					#identityFile = "/home/bluestar/.ssh/frost";
				};
				"monitor" = {
					hostname = "192.168.0.16";
					user = "leopardstar";
					port = 50;
					#identityFile = "/home/bluestar/.ssh/icicle";
				};
				"pihole" = {
					hostname = "192.168.0.214";
					user = "scourge";
					port = 50;
					#identityFile = "/home/bluestar/.ssh/pihole";
				};
			};
		};
		git = {
			enable = true;
			userName = "Blizzard Finnegan";
			userEmail = "blizzardfinnegan@gmail.com";
			diff-so-fancy.enable = true;
			#signing.signByDefault = true;
			#signing.key = "1ADBD1BF";
		};
		tmux = {
			enable = true;
			clock24 = true;
			historyLimit = 100000;
			keyMode = "vi";
			#mouse = true;
			newSession = true;
			shortcut = "a";
			terminal = "screen-256color";
			customPaneNavigationAndResize = true;
			extraConfig = ''
				bind - split-window -v
				bind _ split-window -h
			'';
			plugins = with pkgs.tmuxPlugins; [
				resurrect
				{
					plugin = power-theme;
					extraConfig = ''
						set -g @tmux_power_theme 'forest'
					'';
				}
			];
		};
		neovim = {
			enable = true;
			#defaultEditor = true;
			withNodeJs = true;
			withPython3 = true;
			withRuby = true;
			extraPackages = with pkgs; [ cargo ];
			plugins = with pkgs.vimPlugins; [
				packer-nvim
				vim-nix
				gitsigns-nvim
				nvim-lspconfig
				nvim-treesitter
				nvim-treesitter-textobjects
				lualine-nvim
				nvim-cmp
				nvim-tree-lua
				telescope-nvim
			];
			extraLuaConfig = ''
				vim.cmd [[colorscheme desert]]
				require("nvim-tree").setup()
				require("lualine").setup()
				require("nvim-treesitter.configs").setup {
					highlight = { enable = true },
					indent = { enable = true } ,
				};
			'';
		};
		zsh = {
			enable = true;
			enableCompletion = true;
			enableSyntaxHighlighting = true;
			initExtra = ''
				[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
			'';
			shellAliases = {
				l = "exa -lah";
				zshconfig = "nvim ~/.zshrc";
			};
			history = {
				size = 1000000;
				save = 1000000;
				share = true;
				expireDuplicatesFirst = true;
			};
			prezto = {
				enable = true;
				caseSensitive = false;
				prompt.theme = "powerlevel10k";
				color = true;
				editor.dotExpansion = true;
				utility.safeOps = true;
			};
			sessionVariables.HIST_STAMPS = "dd.mm.yyyy";
		};
	};
	home.stateVersion = "22.11";
  };


  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    nano
    niv
    zsh
    nomachine-client
    wget
    tailscale
    home-manager
    nvidia-docker
    arion
    lazydocker
  ];
  environment.shells = with pkgs; [ zsh ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?

}
