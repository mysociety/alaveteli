{
  applyPatches,
  customAlaveteliPatches,
  fetchFromGitHub,
  postPatch,
}:
applyPatches {
  inherit postPatch;
  src = fetchFromGitHub {
    owner = "mysociety";
    repo = "alaveteli";
    rev = "3019769ac242";
    hash = "sha256-GAtcN9bj7LMF9YkW/L9hiRz/HhERKXdO30CXL7R+tzA=";
    fetchSubmodules = true;
  };
  patches = [
    # move xapiandb out of source tree and into dataDir
    # TODO: these patches hardcode /var/lib/alaveteli, but we should really
    # use cfg.dataDir instead. Maybe use substituteInPlace in postPatch?
    ../patches/models_info_request.patch
    ../patches/models_mail_server_log.patch
    ../patches/models_outgoing_message.patch
    ../patches/public_body_controller.patch
    ../patches/conf_env_prod.patch
    ../patches/lib_acts_as_xapian.patch
    ../patches/lib_configuration.patch
    ../patches/lib_mail_handler.patch
    # ../patches/routes_rb.patch
    ../patches/rakefile.patch
    ../patches/theme_loader_rb.patch
    ../patches/themes_rake.patch
  ]
  ++ customAlaveteliPatches;
}
