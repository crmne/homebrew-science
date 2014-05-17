require "formula"

class TexRequirement < Requirement
  satisfy :build_env => false do
    which 'latex' and which 'dvipng'
  end

  def message; <<-EOS.undent
    LaTeX not found. This is required to build docs for Marsyas.
    If you want, https://www.tug.org/mactex/ provides an installer.
    EOS
  end
end

class Marsyas < Formula
  homepage "http://marsyas.info"
  head "https://github.com/marsyas/marsyas.git"
  url "http://downloads.sourceforge.net/project/marsyas/marsyas/marsyas-0.4.8.tar.gz"
  sha1 "1af165243a144a24ca08386fc1dc9bea4c93517c"

  keg_only "This brew installs more than 30 commands, some with dangerously short names."

  option "with-docs", "Install documentation" if build.head? # TODO: fix the latex in 0.4.8

  depends_on "cmake"        => :build
  depends_on "doxygen"      => :build if build.with? "docs"
  depends_on TexRequirement => :build if build.with? "docs"
  depends_on "qt5"          => :recommended if build.head?
  depends_on "mad"          => :optional
  depends_on "libvorbis"    => :optional
  depends_on "qt"           => :optional # TODO: fix build
  depends_on "libpng"       => :optional
  depends_on "lame"         => :optional
  depends_on "python"       => :optional
  depends_on "swig"         if build.with? "python"

  patch :DATA               if build.head?


  def install
    cmake_args = std_cmake_args
    
    %w{mad libvorbis qt qt5 libpng lame}.each do |feature|
      cmake_args << "-DWITH_#{feature.sub('lib', '').upcase}:BOOL=ON" if build.with? feature
    end

    if build.with? "python"
      cmake_args << "-DWITH_SWIG:BOOL=ON"
      cmake_args << "-DWITH_SWIG_PYTHON:BOOL=ON"
    end

    cmake_args << "-DWITH_QT:BOOL=OFF" if build.without? "qt5" and build.without? "qt"
    cmake_args << "-DMARSYAS_TESTS:BOOL=ON"

    cmake_dir = build.head? ? "." : "src"

    system "cmake", cmake_dir, *cmake_args
    system "make", "install"

    if build.with? "docs"
      system "make", "docs" if build.head?
      
      cd "doc" do
        system "cmake", ".", *cmake_args
        system "make", "docs"
      end if not build.head?
      
      doc.install "doc/out-www/"
    end
  end

  test do
    system "make", "test"
  end
end

__END__
diff --git a/src/qt5apps/inspector/CMakeLists.txt b/src/qt5apps/inspector/CMakeLists.txt
index b569082..7100ee7 100644
--- a/src/qt5apps/inspector/CMakeLists.txt
+++ b/src/qt5apps/inspector/CMakeLists.txt
@@ -72,9 +72,7 @@ if(APPLE)
     ${bundle_dir}/Contents/MacOS/marsyas-run
     ${bundle_dir}/Contents/plugins/platforms/libqcocoa.dylib
     ${bundle_dir}/Contents/qml/QtQuick.2/libqtquick2plugin.dylib
-    ${bundle_dir}/Contents/qml/QtQuick.2/libqtquick2plugin_debug.dylib
     ${bundle_dir}/Contents/qml/QtQuick/Layouts/libqquicklayoutsplugin.dylib
-    ${bundle_dir}/Contents/qml/QtQuick/Layouts/libqquicklayoutsplugin_debug.dylib
   )
 
   install(CODE "

diff --git a/src/qt5apps/inspector/CMakeLists.txt b/src/qt5apps/inspector/CMakeLists.txt
index 7100ee7..c1ab9b5 100644
--- a/src/qt5apps/inspector/CMakeLists.txt
+++ b/src/qt5apps/inspector/CMakeLists.txt
@@ -77,6 +77,7 @@ if(APPLE)
 
   install(CODE "
 include(BundleUtilities)
+set(BU_CHMOD_BUNDLE_ITEMS ON)
 fixup_bundle(
   \"${bundle_dir}\"
   \"${extra_fixup_items}\"
