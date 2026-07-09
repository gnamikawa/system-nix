{ pkgs, ... }@args:
let
  testDir = ./.;
  fileNames = testDir |> builtins.readDir |> builtins.attrNames;
  isSpecFile = name: (name |> builtins.match ''.*\.spec\.nix'') != null;
  nixFiles = fileNames |> builtins.filter isSpecFile;
  runTest = testFileName: {
    name = testFileName;
    # Path arithmetic, not string interpolation: "${testDir}/${name}" loses
    # the flake source accessor (lazy trees), which breaks module-key
    # matching, e.g. disabledModules in carve-out.nix.
    value = args |> import (testDir + "/${testFileName}") |> pkgs.testers.runNixOSTest;
  };
  testResults = nixFiles |> builtins.map runTest;
in
builtins.listToAttrs testResults
