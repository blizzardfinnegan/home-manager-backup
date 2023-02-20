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

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  #Packages to install
  home.packages = [
    pkgs.tmux
    pkgs.neovim
    pkgs.git
  ];

  home.file.".config/nvim".source = ./nvim;

  programs.git = {
    enable = true;
    userName = "Blizzard Finnegan";
    userEmail = "blizzardfinnegan@gmail.com";
  };
}
