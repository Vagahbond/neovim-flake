{lib, ...}: let
  inherit (lib.options) mkEnableOption;
in {
  options.vim.utility.diffview-nvim = {
    enable = mkEnableOption "diffview-nvim: cycle through diffs for all modified files for any git rev";
  };
}
