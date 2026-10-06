let
  # Relative to the home directory. Home Manager creates it below, while
  # Firefox's ${home} policy variable expands to the native macOS home path.
  downloadDirectory = "firefoxDownloads";
in
{
  # Firefox does not reliably create a nonstandard download directory itself.
  # Managing one harmless marker file makes Home Manager create the directory.
  home.file."${downloadDirectory}/.keep".text = "";

  textfox = {
    enable = true;
    profiles = [ "denikon" ];

    config.tabs = {
      horizontal.enable = false;
      # vertical.enable = true;
      # vertical.sidebery.enable = false;
      # vertical.sidebery.margin = "1.0rem";
    };
  };

  programs.firefox = {
    enable = true;
    languagePacks = [ "en-US" ];

    profiles.denikon = {
      id = 0;
      isDefault = true;

      bookmarks = import ./firefox-bookmarks.nix;

      settings = {
        # Keep the newer multi-profile UI hidden when using one profile.
        "browser.profiles.enabled" = false;

        # Textfox / ShyFox integration.
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "shyfox.enable.ext.mono.toolbar.icons" = true;
        "shyfox.enable.ext.mono.context.icons" = true;
        "shyfox.enable.context.menu.icons" = true;

        # Remove sponsored content and recommendations.
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.system.showSponsored" = false;
        "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsored" = false;
        "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
        "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
        "extensions.getAddons.showPane" = false;
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "browser.discovery.enabled" = false;

        # Remove first-run and update interruptions.
        "browser.shell.checkDefaultBrowser" = false;
        "browser.preferences.moreFromMozilla" = false;
        "browser.aboutConfig.showWarning" = false;
        "browser.startup.homepage_override.mstone" = "ignore";
        "browser.aboutwelcome.enabled" = false;
        "browser.urlbar.scotchBonnet.enableOverride" = false;

        "browser.toolbars.bookmarks.visibility" = "always";
      };

      containersForce = true;
      containers = {
        Work = {
          icon = "briefcase";
          color = "blue";
          id = 99;
        };

        THV = {
          icon = "pet";
          color = "blue";
          id = 100;
        };

        Personal = {
          icon = "chill";
          color = "green";
          id = 101;
        };

        "Do Not Disturb" = {
          icon = "fingerprint";
          color = "purple";
          id = 102;
        };
      };
    };

    policies = {
      # Force downloads into ~/firefoxDownloads. Unlike
      # DefaultDownloadDirectory, this policy also sets useDownloadDir.
      DownloadDirectory = "\${home}/${downloadDirectory}";
      PromptForDownloadLocation = false;

      # Firefox is updated through Nix/Home Manager.
      DisableAppUpdate = true;

      # Always start with a blank page and make new tabs blank as well.
      Homepage = {
        URL = "about:blank";
        StartPage = "none";
        Locked = true;
        NewTabOnRestore = false;
      };
      NewTabPage = false;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";

      SearchEngines = {
        Default = "DuckDuckGo";
        Remove = [
          "Google"
          "Ecosia"
          "Bing"
        ];
      };

      # Bitwarden is used instead of Firefox's password manager.
      OfferToSaveLogins = false;
      PasswordManagerEnabled = false;

      DisableBuiltinPDFViewer = false;
      PDFjs = {
        Enabled = true;
        EnablePermissions = false;
      };

      FirefoxSuggest.WebSuggestions = false;

      DisableFeedbackCommands = true;
      DisableFirefoxAccounts = true;
      DisableFirefoxScreenshots = true;
      DisablePocket = true;
      DisableSetDesktopBackground = true;
      DontCheckDefaultBrowser = true;

      GenerativeAI.Enabled = false;
      HardwareAcceleration = true;
      PrintingEnabled = false;

      DisableFirefoxStudies = true;
      DisableFormHistory = true;
      DisableTelemetry = true;

      ExtensionSettings = {
        # Block extensions other than those explicitly declared below.
        "*".installation_mode = "blocked";

        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };

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

        # Vimium C
        "vimium-c@gdh1995.cn" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4474326/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };

        # QrCode generator
        "jid1-ZSMfwe4lCAw9oQ@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/file/4058188/latest.xpi";
          installation_mode = "force_installed";
          default_area = "navbar";
        };
      };
    };
  };
}
