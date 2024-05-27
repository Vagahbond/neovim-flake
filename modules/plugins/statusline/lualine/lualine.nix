{
  config,
  lib,
  ...
}: let
  inherit (builtins) elem;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.types) int bool str listOf enum;
  inherit (lib.lists) optional;
  inherit (lib.nvim.types) mkPluginSetupOption;

  supported_themes = import ./supported_themes.nix;
  builtin_themes = import ./builtin_themes.nix;

  mkLualineSectionOption = import ./section_options.nix {inherit lib;};
in {
  options.vim.statusline.lualine = {
    enable = mkEnableOption "lualine statusline plugin";
    setupOpts = mkPluginSetupOption "Lualine" {};

    icons.enable = mkEnableOption "icons for lualine" // {default = true;};

    refresh = {
      statusline = mkOption {
        type = int;
        description = "Refresh rate for lualine";
        default = 1000;
      };

      tabline = mkOption {
        type = int;
        description = "Refresh rate for tabline";
        default = 1000;
      };

      winbar = mkOption {
        type = int;
        description = "Refresh rate for winbar";
        default = 1000;
      };
    };

    globalStatus = mkOption {
      type = bool;
      description = "Enable global status for lualine";
      default = true;
    };

    alwaysDivideMiddle = mkOption {
      type = bool;
      description = "Always divide middle section";
      default = true;
    };

    disabledFiletypes = mkOption {
      type = listOf str;
      description = "Filetypes to disable lualine on";
      default = ["alpha"];
    };

    ignoreFocus = mkOption {
      type = listOf str;
      default = ["NvimTree"];
      description = ''
        If current filetype is in this list it'll always be drawn as inactive statusline
        and the last window will be drawn as active statusline.
      '';
    };

    theme = let
      themeSupported = elem config.vim.theme.name supported_themes;
      themesConcatted = builtin_themes ++ optional themeSupported config.vim.theme.name;
    in
      mkOption {
        type = enum themesConcatted;
        default = "auto";
        # TODO: xml generation error if the closing '' is on a new line.
        # issue: https://gitlab.com/rycee/nmd/-/issues/10
        defaultText = ''`config.vim.theme.name` if theme supports lualine else "auto"'';
        description = "Theme for lualine";
      };

    sectionSeparator = {
      left = mkOption {
        type = str;
        description = "Section separator for left side";
        default = "";
      };

      right = mkOption {
        type = str;
        description = "Section separator for right side";
        default = "";
      };
    };

    componentSeparator = {
      left = mkOption {
        type = str;
        description = "Component separator for left side";
        default = "";
      };

      right = mkOption {
        type = str;
        description = "Component separator for right side";
        default = "";
      };
    };

    activeSection = {
      a = mkLualineSectionOption {
        description = "active config for: | (A) | B | C       X | Y | Z |";
        default = [
          {
            content = "mode";
            iconsEnabled = true;
            separator = {
              left = "▎";
              right = "";
            };
          }
          {
            drawEmpty = true;
            separator = {
              left = "";
              right = "";
            };
          }
        ];
      };
      b = mkLualineSectionOption {
        description = "active config for: | A | (B) | C       X | Y | Z |";
        default = [
          {
            content = "filetype";
            colored = true;
            iconOnly = true;
            icon = {align = "left";};
          }
          {
            content = "filename";
            symbols = {
              modified = " ";
              readonly = " ";
            };
            separator = {right = "";};
          }
          {
            drawEmpty = true;
            separator = {
              left = "";
              right = "";
            };
          }
        ];
      };

      c = mkLualineSectionOption {
        description = "active config for: | A | B | (C)       X | Y | Z |";
        default = [
          {
            content = "diff";
            colored = false;
            diffColor = {
              added = "DiffAdd";
              modified = "DiffChange";
              removed = "DiffDelete";
            };
            symbols = {
              added = "+";
              modified = "~";
              removed = "-";
            };
            separator = {right = "";};
          }
        ];
      };

      x = mkLualineSectionOption {
        description = "active config for: | A | B | C       (X) | Y | Z |";
        default = [
          {
            content = ''
              function()
                local buf_ft = vim.api.nvim_get_option_value('filetype', {})

                -- List of buffer types to exclude
                local excluded_buf_ft = {"toggleterm", "NvimTree", "TelescopePrompt"}

                -- Check if the current buffer type is in the excluded list
                for _, excluded_type in ipairs(excluded_buf_ft) do
                  if buf_ft == excluded_type then
                    return ""
                  end
                end

                -- Get the name of the LSP server active in the current buffer
                local clients = vim.lsp.get_active_clients()
                local msg = 'No Active Lsp'

                -- if no lsp client is attached then return the msg
                if next(clients) == nil then
                  return msg
                end

                for _, client in ipairs(clients) do
                  local filetypes = client.config.filetypes
                  if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
                    return client.name
                  end
                end

                return msg
              end,
            '';
            icon = " ";
            separator = {left = "";};
          }
          {
            content = "diagnostics";
            sources = ["nvim_lsp" "nvim_diagnostic" "nvim_diagnostic" "vim_lsp" "coc"];
            symbols = {
              error = "󰅙  ";
              warn = "  ";
              info = "  ";
              hint = "󰌵 ";
            };
            colored = true;
            updateInInsert = false;
            alwaysVisible = false;
            diagnosticsColor = {
              color_error = {fg = "red";};
              color_warn = {fg = "yellow";};
              color_info = {fg = "cyan";};
            };
          }
        ];
      };

      y = mkLualineSectionOption {
        description = "active config for: | A | B | C       X | (Y) | Z |";
        default = [
          {
            drawEmpty = true;
            separator = {
              left = "";
              right = "";
            };
          }
          {
            content = "searchcount";
            maxcount = 999;
            timeout = 120;
            separator = {left = "";};
          }
          {
            content = "branch";
            icon = " •";
            separator = {left = "";};
          }
        ];
      };

      z = mkLualineSectionOption {
        description = "active config for: | A | B | C       X | Y | (Z) |";
        default = [
          {
            drawEmpty = true;
            separator = {
              left = "";
              right = "";
            };
          }
          {
            content = "progress";
            separator = {left = "";};
          }
          {content = "location";}
          {
            content = "fileformat";
            color = {fg = "black";};
            symbols = {
              unix = "'";
              dos = "'";
              mac = "'";
            };
          }
        ];
      };
    };

    extraActiveSection = {
      a = mkLualineSectionOption {
        description = "Extra entries for activeSection.a";
        default = [];
      };

      b = mkLualineSectionOption {
        description = "Extra entries for activeSection.b";
        default = [];
      };

      c = mkLualineSectionOption {
        description = "Extra entries for activeSection.c";
        default = [];
      };

      x = mkLualineSectionOption {
        description = "Extra entries for activeSection.x";
        default = [];
      };

      y = mkLualineSectionOption {
        description = "Extra entries for activeSection.y";
        default = [];
      };

      z = mkLualineSectionOption {
        description = "Extra entries for activeSection.z";
        default = [];
      };
    };

    inactiveSection = {
      a = mkLualineSectionOption {
        description = "inactive config for: | (A) | B | C       X | Y | Z |";
        default = [];
      };

      b = mkLualineSectionOption {
        description = "inactive config for: | A | (B) | C       X | Y | Z |";
        default = [];
      };

      c = mkLualineSectionOption {
        description = "inactive config for: | A | B | (C)       X | Y | Z |";
        default = [{content = "filename";}];
      };

      x = mkLualineSectionOption {
        description = "inactive config for: | A | B | C       (X) | Y | Z |";
        default = [{contentn = "location";}];
      };

      y = mkLualineSectionOption {
        description = "inactive config for: | A | B | C       X | (Y) | Z |";
        default = [];
      };

      z = mkLualineSectionOption {
        description = "inactive config for: | A | B | C       X | Y | (Z) |";
        default = [];
      };
    };
    extraInactiveSection = {
      a = mkLualineSectionOption {
        description = "Extra entries for inactiveSection.a";
        default = [];
      };

      b = mkLualineSectionOption {
        description = "Extra entries for inactiveSection.b";
        default = [];
      };

      c = mkLualineSectionOption {
        description = "Extra entries for inactiveSection.c";
        default = [];
      };

      x = mkLualineSectionOption {
        description = "Extra entries for inactiveSection.x";
        default = [];
      };

      y = mkLualineSectionOption {
        description = "Extra entries for inactiveSection.y";
        default = [];
      };

      z = mkLualineSectionOption {
        description = "Extra entries for inactiveSection.z";
        default = [];
      };
    };
  };
}
