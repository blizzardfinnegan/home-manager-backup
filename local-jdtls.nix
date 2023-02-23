{stdenvNoCC, fetchurl, ...}:
stdenvNoCC.mkDerivation {
  name = "local-jdtls";
  src = fetchurl {
    url = "https://download.eclipse.org/jdtls/milestones/1.9.0/jdt-language-server-1.9.0-202203031534.tar.gz";
    sha256 = "sha256-uK8ZJcs7gX/RBh4ApF/7xqynaBnYsvWTliYAnr9DL8c=";
  };
  dontUnpack = true;
  installPhase = 
  ''
  mkdir -p $out
  tar -xf $src -C $out
  '';
}
