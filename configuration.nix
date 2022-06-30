{pkgs, inputs, lib, ...}: {
  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,115200"
    "earlycon=sbi"

    # https://github.com/starfive-tech/linux/issues/14
    "stmmac.chain_mode=1"
  ];
  boot.initrd.kernelModules = ["dw-axi-dmac-platform" "dw_mmc-pltfm" "spi-dw-mmio"];

  services = {
    openssh.enable = true;
  };

  environment = {
    etc = {
      "nix/flake-channels/system".source = inputs.self;
      "nix/flake-channels/nixpkgs".source = inputs.nixpkgs;
      "nix/flake-channels/home-manager".source = inputs.hm;
    };

    shellAliases = {
      "np-riscv#" = "np-riscv#legacyPackages.x86_64-linux.pkgsCross.riscv64-linux#";
    };

    systemPackages = with pkgs; [
      file
      git
      helix
      lm_sensors
      neofetch
      python3
    ];

    pathsToLink = ["/share/zsh"];
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    # saves space
    supportedLocales = ["en_US.UTF-8/UTF-8"];
  };

  networking.hostName = "visionfive";

  nix = {
    extraOptions = ''
      builders-use-substitutes = true
      experimental-features = nix-command flakes

      # for direnv GC roots
      keep-outputs = true
      keep-derivations = true
    '';

    buildMachines = [
      {
        system = "aarch64-linux";
        sshUser = "root";
        sshKey = "/root/.ssh/arm-server.key";
        maxJobs = 4;
        hostName = "arm-server";
        supportedFeatures = ["nixos-test" "benchmark" "kvm" "big-parallel"];
      }
      {
        system = "x86_64-linux";
        sshUser = "root";
        sshKey = "/root/.ssh/id_ed25519";
        maxJobs = 8;
        hostName = "io";
        supportedFeatures = ["nixos-test" "benchmark" "kvm" "big-parallel"];
      }
    ];
    distributedBuilds = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };

    registry = lib.mapAttrs (n: v: {flake = v;}) inputs;

    nixPath = [
      "nixpkgs=/etc/nix/flake-channels/nixpkgs"
      "home-manager=/etc/nix/flake-channels/home-manager"
    ];

    settings = {
      auto-optimise-store = true;
      substituters = ["https://cache.nichi.co"];
      trusted-public-keys = ["hydra.nichi.co-0:P3nkYHhmcLR3eNJgOAnHDjmQLkfqheGyhZ6GLrUVHwk="];
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
  };

  services = {
    avahi = {
      enable = true;
      nssmdns = true;
      publish = {
        enable = true;
        domain = true;
        addresses = true;
      };
    };
    tailscale.enable = true;
  };

  time.timeZone = "Europe/Bucharest";

  users = {
    users.mihai = {
      extraGroups = ["wheel"];
      isNormalUser = true;
      password = "starfive";
      shell = pkgs.zsh;
    };
  };
}
