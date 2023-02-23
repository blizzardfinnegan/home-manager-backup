{ config, pkgs, ... }:
{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "firestar";
  home.homeDirectory = "/home/firestar";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.packageOverrides = pkgs: {
    nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") { inherit pkgs; };
  };


  #Add new fonts
  fonts.fontconfig.enable = true;

  #Packages to install
  home = {
    packages = with pkgs; [
      tdesktop
      discord
      maven
      nerdfonts
      bitwarden
      yubioath-desktop
      links2
      gnupg
      openssh
      jdk11
      rsync
      btop
      vifm
      librewolf
      vlc
      libsForQt5.bismuth
      nomachine-client
    ];
    sessionPath = ["$HOME/.local/bin" ];
  };

  manual = {
    json.enable = true;
    manpages.enable = true;
  };

  news.display = "show";

  programs = {

    home-manager.enable = true;

    btop.enable = true;

    command-not-found.enable = true;

    exa.enable = true;

    firefox = {
      enable = true;
      profiles.default = {
        name = "default";
        search = {
          default = "DuckDuckGo";
        };
        id = 0;
        bookmarks = [ ];
        extensions = with pkgs.nur.repos.rycee.firefox-addons; [
         bitwarden
         multi-account-containers
         darkreader
         protondb-for-steam
         return-youtube-dislikes
         single-file
         sponsorblock
         steam-database
         ublock-origin
         wayback-machine
        ];
      };
    };

    gpg.enable = true;

    librewolf.enable = true;

    man.enable = true;

    ssh = {
      enable = true;
      hashKnownHosts = true;
      #Uncomment IdentityFiles after generation and sharing
      matchBlocks = {
        "tailServer" = {
          hostname = "100.89.47.123";
          user = "bluestar";
          port = 50;
          identityFile = "${config.home.homeDirectory}/.ssh/snowglobe";
        };
        "homeServer" = {
          hostname = "192.168.0.228";
          user = "bluestar";
          port = 50;
          identityFile = "${config.home.homeDirectory}/.ssh/snowglobe";
        };
        "github" = {
          hostname = "github.com";
          user = "git";
          identityFile = "${config.home.homeDirectory}/.ssh/github";
        };
      };
    };

    texlive.enable = true;

    kitty = {
      enable = true;
      environment = {
       "EDITOR" = "nvim";
      };
      font.size = 10;
      font.name = "Meslo LG S Regular Nerd Font Mono Windows Compatible";
      settings = {
        editor = "nvim";
        shell = "tmux attach";
      };
    };

    git = {
      enable = true;
      userName = "Blizzard Finnegan";
      userEmail = "blizzardfinnegan@gmail.com";
      diff-so-fancy.enable = true;
      signing.signByDefault = true;
      #Fill in with GPG key on generation
      signing.key = "1ADBD1BF";
    };

    tmux = {
      enable = true;
      clock24 = true;
      historyLimit = 100000;
      keyMode = "vi";
      mouse = true;
      newSession = true;
      shortcut = "a";
      terminal = "screen-256color";
      shell = "${pkgs.zsh}/bin/zsh";
      customPaneNavigationAndResize = true;
      extraConfig = ''
        bind - split-window -v
        bind _ split-window -h
        '';
      plugins = with pkgs.tmuxPlugins; [
        cpu
        resurrect
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '60'
            '';
        }
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
      defaultEditor = true;
      withNodeJs = true;
      withPython3 = true;
      withRuby = true;
      extraPackages = with pkgs; [ cargo ];
      plugins = with pkgs.vimPlugins; [
        packer-nvim
        vim-nix
        gitsigns-nvim
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
        nvim-treesitter-textobjects
        lualine-nvim
        nvim-cmp
        #nvim-jdtls
        #{ 
        #  plugin = nvim-jdtls;
        #  config = ''
        #    local project_name = vim.fn.fnamemodify(vim.fn.cwd(), ':p:h:t')
        #  local home = '${config.home.homeDirectory}
        #  local workspace_dir = home .. '/.local/jdtls/workspaces/' .. project_name
        #  local plugin_location = home .. '/.local/jdtls/plugins/org.eclipse.equinox.launcher_1.6.400.v2021924-0641.jar'
        #  local config_location = home .. '/.local/jdtls/config_linux'
        #  local binary_location = home .. '/.local/jdtls/bin/jdtls'
        #  local config = {
        #    cmd = {'java', '-jar', plugin_location, '-configuration', config_location, '-data', workspace_dir, binary_location},
        #    root_dir = vim.fs.dirname(vim.fs.find({'.gradelw','.git','mvnw'}, {upward = true })[1]),
        #  }
        #  require('jdtls').start_or_attach(config)
        #  '';
        #}
        nvim-tree-lua
        telescope-nvim
      ];
      extraLuaConfig = ''
        vim.cmd [[colorscheme desert]]
        require("nvim-tree").setup()
        require("lualine").setup()
        require('nvim-treesitter.configs').setup {
          highlight = { enable = true },
          indent = { enable = true },
        }
        '';
    };

    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      initExtra = ''
        [[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
        '';
      #add the following to system configuration:
      #environment.pathsToLink = [ "/share/zsh" ];
      enableSyntaxHighlighting = true;
      shellAliases = {
        l = "exa -lah";
        zshconfig = "nvim ~/.zshrc";
      };
      history = {
        size = 100000;
        save = config.programs.zsh.history.size;
        share = true;
        extended = true;
        expireDuplicatesFirst = true;
      };
      prezto = {
        enable = true;
        caseSensitive = false;
        prompt.theme = "powerlevel10k";
        color = true;
        editor.dotExpansion = true;
        tmux.autoStartLocal = true;
        utility.safeOps = true;
        #ssh.identities = [ ];
      };
      sessionVariables = {
        EDITOR = "nvim";
        HIST_STAMPS = "dd.mm.yyyy";
      };
    };
  };
}
