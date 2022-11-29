{ mkDerivation
, lib
, stdenv
, fetchurl
, cmake
, extra-cmake-modules
, makeWrapper
, python3Packages
, karchive
, kconfig
, kwidgetsaddons
, kcompletion
, kcoreaddons
, kguiaddons
, ki18n
, kitemmodels
, kitemviews
, kwindowsystem
, kio
, kcrash
, breeze-icons
, boost
, libraw
, fftw
, eigen
, exiv2
, lcms2
, gsl
, openexr
, libheif
, giflib
, openjpeg
, opencolorio_1
, poppler
, curl
, ilmbase
, libmypaint
, libwebp
, qtmultimedia
, qtx11extras
, quazip
, xsimd
, gmic-qt
, withGmic ? true
}:

let
  gmic-qt-krita = gmic-qt.override {
    variant = "krita-plugin";
  };
in
mkDerivation rec {
  pname = "krita";
  version = "5.1.3";

  src = fetchurl {
    url = "https://download.kde.org/stable/${pname}/${version}/${pname}-${version}.tar.gz";
    sha256 = "sha256-69+P0wMIciGxuc6tmWG1OospmvvwcZl6zHNQygEngo0=";
  };

  nativeBuildInputs = [ cmake extra-cmake-modules python3Packages.sip makeWrapper ];

  buildInputs = [
    python3Packages.pyqt5
    karchive
    kconfig
    kwidgetsaddons
    kcompletion
    kcoreaddons
    kguiaddons
    ki18n
    kitemmodels
    kitemviews
    kwindowsystem
    kio
    kcrash
    breeze-icons
    boost
    libraw
    fftw
    eigen
    exiv2
    lcms2
    gsl
    openexr
    libheif
    giflib
    openjpeg
    opencolorio_1
    poppler
    curl
    ilmbase
    libmypaint
    libwebp
    qtmultimedia
    qtx11extras
    quazip
    xsimd
  ];

  NIX_CFLAGS_COMPILE = [ "-I${ilmbase.dev}/include/OpenEXR" ]
    ++ lib.optional stdenv.cc.isGNU "-Wno-deprecated-copy";

  # Krita runs custom python scripts in CMake with custom PYTHONPATH which krita determined in their CMake script.
  # Patch the PYTHONPATH so python scripts can import sip successfully.
  postPatch =
    let
      pythonPath = python3Packages.makePythonPath (with python3Packages; [ sip setuptools ]);
    in
    ''
      substituteInPlace cmake/modules/FindSIP.cmake \
        --replace 'PYTHONPATH=''${_sip_python_path}' 'PYTHONPATH=${pythonPath}'
      substituteInPlace cmake/modules/SIPMacros.cmake \
        --replace 'PYTHONPATH=''${_krita_python_path}' 'PYTHONPATH=${pythonPath}'
    '';

  cmakeFlags = [
    "-DPYQT5_SIP_DIR=${python3Packages.pyqt5}/${python3Packages.python.sitePackages}/PyQt5/bindings"
    "-DPYQT_SIP_DIR_OVERRIDE=${python3Packages.pyqt5}/${python3Packages.python.sitePackages}/PyQt5/bindings"
    "-DCMAKE_BUILD_TYPE=RelWithDebInfo"
  ];

  preInstall = ''
    qtWrapperArgs+=(--prefix PYTHONPATH : "$PYTHONPATH")
  '';

  postInstall =
    if withGmic then
      ''
        cp -r ${gmic-qt-krita}/lib $out
        cp -r ${gmic-qt-krita}/share $out
      ''
    else
      null;

  meta = with lib; {
    description = "A free and open source painting application";
    homepage = "https://krita.org/";
    maintainers = with maintainers; [ abbradar sifmelcara nek0 shiryel ];
    platforms = platforms.linux;
    license = licenses.gpl3Only;
  };
}
