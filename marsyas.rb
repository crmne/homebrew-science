require "formula"

class Marsyas < Formula
  homepage "http://marsyas.info"
  head "https://github.com/marsyas/marsyas.git"
  url "https://downloads.sourceforge.net/project/marsyas/marsyas/marsyas-0.4.8.tar.gz"
  sha1 "1af165243a144a24ca08386fc1dc9bea4c93517c"

  keg_only "This brew installs more than 30 commands, some with dangerously short names."

  option "with-docs", "Install documentation" # FIXME: 0.4.8 fails to build documentation

  depends_on "cmake"        => :build
  depends_on "doxygen"      => :build if build.with? "docs"
  depends_on :tex           => :build if build.with? "docs"
  depends_on "qt5"          => :recommended if build.head?
  depends_on "mad"          => :optional
  depends_on "libvorbis"    => :optional
  depends_on "qt"           => :optional # FIXME: cmake fails to recognize qt4 if qt5 is installed
  depends_on "libpng"       => :optional
  depends_on "lame"         => :optional
  depends_on "python"       => :optional
  depends_on "swig"         if build.with? "python"

  # fix the creation of the app bundle of Marsyas Inspector.app
  # which is only available in HEAD at the moment
  # and a bug in SoundFileSink.cpp
  patch :DATA               if build.head?

  def install
    # fixes "fatal error: 'ft2build.h' file not found" by using cmake's default module
    rm "cmake-modules/FindFreetype.cmake"

    cmake_args = std_cmake_args

    %w{mad libvorbis libpng lame}.each do |feature|
      cmake_args << "-DWITH_#{feature.sub('lib', '').upcase}:BOOL=ON" if build.with? feature
    end

    if build.with? "python"
      cmake_args << "-DWITH_SWIG:BOOL=ON"
      cmake_args << "-DWITH_SWIG_PYTHON:BOOL=ON"
    end

    # in HEAD QT means QT5, in stable QT means QT4
    cmake_args << "-DWITH_QT:BOOL=OFF" if build.head? and build.without? "qt5"
    cmake_args << "-DWITH_QT4:BOOL=ON" if build.head? and build.with? "qt"
    cmake_args << "-DWITH_QT:BOOL=ON" if (not build.head?) and build.with? "qt"
    
    cmake_args << "-DMARSYAS_TESTS:BOOL=ON"
    cmake_args << "-DWITH_OPENGL:BOOL=ON"

    cmake_dir = build.head? ? "." : "src"

    system "cmake", cmake_dir, *cmake_args
    system "make", "install"
    system "make", "test"

    if build.with? "docs"
      system "make", "docs" if build.head?

      cd "doc" do
        system "cmake", ".", *cmake_args
        system "make", "docs"
      end if not build.head?

      doc.install "doc/out-www/"
    end
  end
end

__END__
diff --git a/src/qt5apps/inspector/CMakeLists.txt b/src/qt5apps/inspector/CMakeLists.txt
index b569082..c1ab9b5 100644
--- a/src/qt5apps/inspector/CMakeLists.txt
+++ b/src/qt5apps/inspector/CMakeLists.txt
@@ -72,13 +72,12 @@ if(APPLE)
     ${bundle_dir}/Contents/MacOS/marsyas-run
     ${bundle_dir}/Contents/plugins/platforms/libqcocoa.dylib
     ${bundle_dir}/Contents/qml/QtQuick.2/libqtquick2plugin.dylib
-    ${bundle_dir}/Contents/qml/QtQuick.2/libqtquick2plugin_debug.dylib
     ${bundle_dir}/Contents/qml/QtQuick/Layouts/libqquicklayoutsplugin.dylib
-    ${bundle_dir}/Contents/qml/QtQuick/Layouts/libqquicklayoutsplugin_debug.dylib
   )
 
   install(CODE "
 include(BundleUtilities)
+set(BU_CHMOD_BUNDLE_ITEMS ON)
 fixup_bundle(
   \"${bundle_dir}\"
   \"${extra_fixup_items}\"

diff --git a/src/marsyas/marsystems/SoundFileSink.cpp b/src/marsyas/marsystems/SoundFileSink.cpp
index 56b272a..f1f16de 100644
--- a/src/marsyas/marsystems/SoundFileSink.cpp
+++ b/src/marsyas/marsystems/SoundFileSink.cpp
@@ -124,7 +124,7 @@ SoundFileSink::updateBackend()
 #ifdef MARSYAS_LAME
   else if (ext == ".mp3")
   {
-    dest_ = new MP3FileSink(getName());
+    backend_ = new MP3FileSink(getName());
   }
 #endif
   else
