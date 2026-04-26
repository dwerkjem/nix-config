{ pkgs, ... }:

let
  kanataConfig = ''
    (defcfg
      process-unmapped-keys yes
      danger-enable-cmd yes)

    (defsrc
      caps lctl lalt ralt rctl t)

    (defalias
      cap (tap-hold 200 200 esc lctl)
      open-terminal (cmd ${pkgs.alacritty}/bin/alacritty -e ${pkgs.zsh}/bin/zsh)
      t-action (switch
        ((or
          (and lctl lalt)
          (and lctl ralt)
          (and rctl lalt)
          (and rctl ralt))) @open-terminal break
        () t break))

    (deflayer base
      @cap lctl lalt ralt rctl @t-action))
  '';
in
{
  home.packages = [ pkgs.kanata-with-cmd ];

  home.file.".config/kanata/kanata.kbd".text = kanataConfig;

  systemd.user.services.kanata = {
    Unit = {
      Description = "Kanata keyboard remapper";
      After = [ "default.target" ];
      PartOf = [ "default.target" ];
    };

    Service = {
      ExecStart = "${pkgs.kanata-with-cmd}/bin/kanata --cfg %h/.config/kanata/kanata.kbd";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install.WantedBy = [ "default.target" ];
  };
}
