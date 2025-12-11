{
  customAlaveteliPatches,
  secretsFile,
  themeGemfile,
  themeLockfile,
  themeGemset,
  themeUrl,
  themeFiles,
  themeTranslationFiles,
  themeProTranslationFiles,
  dataDir,
  pkgs,
}:
{
  alaveteli_develop = pkgs.callPackage ./versions/generic.nix {
    inherit
      customAlaveteliPatches
      secretsFile
      themeGemfile
      themeLockfile
      themeGemset
      themeUrl
      themeFiles
      themeTranslationFiles
      themeProTranslationFiles
      dataDir
      ;
    version = "develop";
  };
  alaveteli_0_46 = pkgs.callPackage ./versions/generic.nix {
    inherit
      customAlaveteliPatches
      secretsFile
      themeGemfile
      themeLockfile
      themeGemset
      themeUrl
      themeFiles
      themeTranslationFiles
      themeProTranslationFiles
      dataDir
      ;
    version = "0_46";
  };
}
