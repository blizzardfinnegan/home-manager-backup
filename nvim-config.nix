{
  stdenvNoCC,
  unpackedJdtls,
  ...
}:
stdenvNoCC.mkDerivation {
  name = "nvim-config";

  src = ./.;

  patchPhase = ''
    # this isnt totally ideal because if you change java.lua this will stop
    # working but hey it works for now
    sed -i "s|home .. '/.local/jdtls|'${unpackedJdtls}|" java.lua
  '';

  installPhase = ''
    mkdir $out/lua
    # if you install this as a plugin, you can then do require("java") to
    # make this file get evaluated
    cp java.lua $out/lua
  '';
}
