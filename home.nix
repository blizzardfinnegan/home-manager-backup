{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "pinestar";
  home.homeDirectory = "/home/pinestar";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";


  #Add new fonts
  fonts.fontconfig.enable = true;

  #Packages to install
  home = {
    packages = with pkgs; [
      exa
      zsh
      tmux
      neovim
      tdesktop
      discord
      st
      git
      maven
      nerdfonts
      bitwarden
      yubioath-desktop
      links
      gnugpg
      openssh
      jdk11
      rsync
      btop
      kitty
      vifm
      librewolf
      vlc
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

    firefox.enable = true;

    gpg.enable = true;

    java.enable = true;

    librewolf.enable = true;

    man.enable = true;

    ssh = {
      enable = true;
      hashKnownHosts = true;
      matchBlock = {
        "tailServer" = {
          hostname = "100.89.47.123";
          user = "bluestar";
          port = "50";
          #identityFile = 
        };
        "homeServer" = {
          hostname = "192.168.0.228";
          user = "bluestar";
          port = "50";
          #identityFile = 
        };
        "github" = {
          hostname = "github.com";
          user = "git";
          #identityFile = 
        };
      };
    };

    texlive.enable = true;

    kitty = {
      enable = true;
      #environment = {
      # "EDITOR" = "nvim";
      #};
      font.size = 12;
    };

    git = {
      enable = true;
      userName = "Blizzard Finnegan";
      userEmail = "blizzardfinnegan@gmail.com";
      diff-so-fancy.enable = true;
      signing.signByDefault = false;
    };

    tmux = {
      enable = true;
      clock24 = true;
      historyLimit = 100000;
      keyMode = "vi";
      mouse = true;
      newSession = true;
      shortct = "a";
      terminal = "screen-256color";
      #shell = "\${pkgs.zsh}/bin/zsh"
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
        nvim-treesitter
        nvim-treesitter-textobjects
        lualine-nvim
        nvim-cmp
        { 
          plugin = nvim-jdtls;
          config = ''
            local project_name = vim.fn.fnamemodify(vim.fn.cwd(), ':p:h:t')
          local home = '${config.home.homeDirectory}
          local workspace_dir = home .. '/.local/jdtls/workspaces/' .. project_name
          local plugin_location = home .. '/.local/jdtls/plugins/org.eclipse.equinox.launcher_1.6.400.v2021924-0641.jar'
          local config_location = home .. '/.local/jdtls/config_linux'
          local binary_location = home .. '/.local/jdtls/bin/jdtls'
          local config = {
            cmd = {'java', '-jar', plugin_location, '-configuration', config_location, '-data', workspace_dir, binary_location},
            root_dir = vim.fs.dirname(vim.fs.find({'.gradelw','.git','mvnw'}, {upward = true })[1]),
          }
          require('jdtls').start_or_attach(config)
          '';
        }
        nvim-tree-lua
        telescope-nvim
      ];
    };

    zsh = {
      enable = true;
      enableAutosuggestions = true;
      enableCompletion = true;
      #add the following to system configuration:
      #environment.pathsToLink = [ "/share/zsh" ];
      enableSyntaxHighlighting = true;
      shellAliases = {
        l = "exa -lah";
        zshconfig = "nvim ~/.zshrc";
      };
      history = {
        size = 100000;
        save = ${config.programs.zsh.history.size};
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
