{
  textfox = {
    enable = true;
    # Replace with the names of profiles, defined in home-manager, or find existing ones in `about:profiles`
    profiles = [
      "denikon"
      "work"
      "edu"
      "personal"
    ];
    config = {
      tabs = {
        horizontal.enable = false;
        # vertical.enable = true;
        # vertical.sidebery.enable = false;
        # vertical.sidebery.margin = "1.0rem";
      };
    };
  };

  programs.firefox = {
    enable = true;
    languagePacks = [ "en-US" ];

    profiles = {
      denikon = {
        isDefault = true;
        id = 000;
        settings = {
          "browser.startup.homepage" = "";
          "shyfox.enable.ext.mono.toolbar.icons" = true;
          "shyfox.enable.ext.mono.context.icons" = true;
          "shyfox.enable.context.menu.icons" = true;
          # Remove sponsored stuff
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsored" = false;
          "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          # Peskyfox
          "extensions.getAddons.showPane" = false; # disable about:addons' Recommendations pane (uses Google Analytics)
          "extensions.htmlaboutaddons.recommendations.enabled" = false; # disable recommendations in about:addons' Extensions and Themes panes
          "browser.discovery.enabled" = false; # Personalized Extension Recommendations in about:addons and AMO
          "browser.shell.checkDefaultBrowser" = false; # disable Firefox from asking to set as the default browser
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false; # disable Extension Recommendations (CFR: "Contextual Feature Recommender")
          "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false; # disable Extension Recommendations (CFR: "Contextual Feature Recommender")
          "browser.preferences.moreFromMozilla" = false; # hide "More from Mozilla" in Settings
          "browser.aboutConfig.showWarning" = false; # tab and about:config warnings
          "browser.startup.homepage_override.mstone" = "ignore"; # disable welcome notices
          "browser.aboutwelcome.enabled" = false; # disable Intro screens
          "browser.urlbar.scotchBonnet.enableOverride" = false; # disable search engine switcher in the URL bar [FF136+]

          # New Profile Switcher is fundamentally broken atm
          "browser.profiles.enabled" = false; # new profile switcher
        };

        containersForce = true;
        containers = {
          "Vaultwarden" = {
            icon = "fingerprint";
            color = "blue";
            id = 100;
          };
          "GitHub" = {
            icon = "chill";
            color = "purple";
            id = 101;
          };
          "Gmail" = {
            icon = "circle";
            color = "red";
            id = 102;
          };
        };
      };

      personal = {
        id = 001;
        settings = {
        };
      };

      work = {
        id = 002;
        settings = {
        };
      };

      edu = {
        id = 003;
        settings = {
        };
      };

    };

    policies = {
      DefaultDownloadDirectory = "\${home}/firefoxDownloads";
      AppAutoUpdate = false;
      SearchEngines = {
        Default = "DuckDuckGo";
        Remove = [
          "Google"
          "Ecosia"
          "Bing"
        ];
      };
      OfferToSaveLogins = false; # Control whether or not Firefox offers to save passwords.
      # Disable or configure PDF.js, the built-in PDF viewer.
      DisableBuiltinPDFViewer = false;
      PDFjs = {
        Enabled = true;
        EnablePermissions = false; # if set to true, the built-in PDF viewer will honor document permissions like preventing the copying of text.
      };
      FirefoxSuggest = {
        WebSuggestions = false;
      };

      # ----Performance----
      DisableFeedbackCommands = true; # Disable the menus for reporting sites.
      DisableFirefoxAccounts = true; # Disable Firefox Accounts integration (Sync).
      DisableFirefoxScreenshots = true; # Remove access to Firefox Screenshots.
      DisablePocket = true; # Remove Pocket in the Firefox UI.
      DisableSetDesktopBackground = true; # Remove the “Set As Desktop Background…” menuitem when right clicking on an image.
      DontCheckDefaultBrowser = true; # Don’t check if Firefox is the default browser at startup.
      # Configure generative AI features.
      GenerativeAI = {
        Enabled = false;
      };
      HardwareAcceleration = true; # Control hardware acceleration.
      PasswordManagerEnabled = false; # Remove (some) access to the password manager.
      PrintingEnabled = false; # Enable or disable printing.

      # ----Privacy----
      DisableFirefoxStudies = true; # Disable Firefox studies (Shield).
      DisableFormHistory = true; # Turn off saving information on web forms and the search bar.
      DisableTelemetry = true;

      ExtensionSettings = {
        "*".installation_mode = "blocked"; # blocks all addons except the ones specified below
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        # "keepassxc-browser@keepassxc.org" = {
        #   install_url = "https://addons.mozilla.org/firefox/downloads/latest/keepassxc-browser/latest.xpi";
        #   installation_mode = "force_installed";
        #   default_area = "navbar";
        # };
        # "addon@darkreader.org" = {
        #   install_url = "https://addons.mozilla.org/firefox/downloads/file/4665768/latest.xpi";
        #   installation_mode = "force_installed";
        #   default_area = "navbar";
        # };
        # "clipper@obsidian.md" = {
        #   install_url = "https://addons.mozilla.org/firefox/downloads/file/4707389/latest.xpi";
        #   installation_mode = "force_installed";
        #   default_area = "navbar";
        # };
        # Bitwarden
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4698131/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        # Firefox Multi-Account Containers
        "@testpilot-containers" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4627302/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        # Sidebery
        "{3c078156-979c-498b-8990-85f7987dd929}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4688454/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        # Firefox Color
        "FirefoxColor@mozilla.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/3643624/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        # Unhook for YouTube
        "myallychou@gmail.com" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4263531/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        # Proton VPN
        "vpn@proton.ch" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4773777/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
        # Vimium C by Dahan Gong
        "vimium-c@gdh1995.cn" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4474326/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
      };
    };
  };
}
