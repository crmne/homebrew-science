require "formula"

class Marsyas < Formula
  homepage "http://marsyas.info"

  keg_only "This brew installs more than 30 commands, some with dangerously short names."

  option "with-docs", "Install documentation" unless build.stable? # 0.4.8 fails to build documentation

  depends_on "cmake"        => :build
  depends_on "doxygen"      => :build if build.with? "docs"
  depends_on :tex           => :build if build.with? "docs"
  depends_on "qt5"          => :recommended if build.head? or build.devel?
  depends_on "mad"          => :optional
  depends_on "libvorbis"    => :optional
  depends_on "qt"           => :optional # FIXME: cmake fails to recognize qt4 if qt5 is installed
  depends_on "libpng12"     => :optional
  depends_on "zlib"         => :build if build.with? "libpng12"
  depends_on "lame"         => :optional
  depends_on :python        => :optional
  depends_on :python3       => :optional
  depends_on "swig"         if build.with? 'python' or build.with? 'python3'

  stable do
    url "https://downloads.sourceforge.net/project/marsyas/marsyas/marsyas-0.4.8.tar.gz"
    sha1 "1af165243a144a24ca08386fc1dc9bea4c93517c"

    # TODO fix the docs build error on stable
    patch do
      url 'https://gist.githubusercontent.com/crmne/4f814ebaae8c0d1c6d84/raw/67ae69c30f8c4bdcc9cf1db983c09299a2493e0d/marsyas-doc-improved.patch'
      sha1 'b734dcb93d5a9d43ded0e964388d812133c71db5'
    end
    patch do
      url 'https://gist.githubusercontent.com/anonymous/7eea5245774cbd3b39dc/raw/caf92aa3f6f6db835355bd3268450e57577e43b7/marsyas-docs.patch'
      sha1 '1db6a773d252199cfd9a087a5eabc85a5e685acc'
    end
  end

  devel do
    url 'https://github.com/marsyas/marsyas/archive/version-0.5.0-beta1.tar.gz'
    sha1 '9e8c1e5130d98435073f2fe3d6aac2b47d340d0c'
  end

  head do
    url "https://github.com/crmne/marsyas.git"
  end

  def install
    unless build.head?
      # fixes "fatal error: 'ft2build.h' file not found" by using cmake's default module
      rm "cmake-modules/FindFreetype.cmake"

      rm_rf "src/otherlibs/zlib-1.2.3/"
      rm_rf "src/otherlibs/libpng-1.2.35/"
    end

    cmake_args = std_cmake_args

    %w{mad libvorbis libpng12 lame}.each do |feature|
      cmake_args << "-DWITH_#{feature.sub('lib', '').sub('12', '').upcase}:BOOL=ON" if build.with? feature
    end

    # in HEAD QT means QT5, in stable QT means QT4
    cmake_args << "-DWITH_QT:BOOL=OFF" if build.head? and build.without? "qt5"
    cmake_args << "-DWITH_QT4:BOOL=ON" if build.head? and build.with? "qt"
    cmake_args << "-DWITH_QT:BOOL=ON" if (not build.head?) and build.with? "qt"
    
    cmake_args << "-DMARSYAS_TESTS:BOOL=ON"
    cmake_args << "-DWITH_OPENGL:BOOL=ON"

    cmake_dir = build.head? ? "." : "src"

    if build.with? "python" or build.with? "python3"
      cmake_args << "-DWITH_SWIG:BOOL=ON"
      cmake_args << "-DWITH_SWIG_PYTHON:BOOL=ON"
      Language::Python.each_python(build) do |python, version| # FIXME: fix the build with python2 & 3 at the same time (how?)
        cmake_args << "-DPYTHON_EXECUTABLE=" + which(python)
        cmake_args << "-DPYTHON_INCLUDE_DIR=" + %x{#{python} -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())"}.chomp
        cmake_args << "-DPYTHON_LIBRARY=" + %x{#{python} -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))"}.chomp + '/Python'
        system "cmake", cmake_dir, *cmake_args
        system "make", "install" # FIXME: homebrew doesn't know about the python stuff
        cmake_args.pop(3)
      end
    else
      system "cmake", cmake_dir, *cmake_args
      system "make", "install"
      # FIXME: bundle goes to /HEAD and /HEAD/bin
    end

    # system "make", "test" # FIXME: fix the build with python2 & 3 at the same time (how?)

    if build.with? "docs"
      system "make", "docs" if build.head?

      cd "doc" do
        system "cmake", ".", *cmake_args
        system "make", "docs"
      end if not build.head?

      rm Dir["doc/out-www/manual/marsyas-cookbook.*"].reject { |f| f['doc/out-www/manual/marsyas-cookbook.pdf'] }
      rm Dir["doc/out-www/manual/marsyas-devel.*"].reject { |f| f['doc/out-www/manual/marsyas-devel.pdf'] }
      rm Dir["doc/out-www/manual/marsyas-user.*"].reject { |f| f['doc/out-www/manual/marsyas-user.pdf'] }
      rm Dir["doc/out-www/sourceDoc/_formulas.*"].reject { |f| f['doc/out-www/manual/sourceDoc/_formulas.dvi'] || f['doc/out-www/manual/sourceDoc/_formulas.tex']}
      doc.install Dir["doc/out-www/*"]
    end
  end
end
