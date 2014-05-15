require "formula"

class Rnammer < Formula
  homepage "http://www.cbs.dtu.dk/services/RNAmmer/"
  #doi "10.1093/nar/gkm160"

  # The tarball must be downloaded using this web form:
  # http://www.cbs.dtu.dk/cgi-bin/nph-sw_request?rnammer
  url "file:#{HOMEBREW_CACHE}/rnammer-1.2.tar.Z"
  sha1 "bdb90b3f569e67b7153e55bccd89401cbbf51b42"

  depends_on "hmmer2"

  def patches
    # Fix "unknown platform"
    DATA
  end

  def install
    man1.install "man/rnammer.1"
    rmdir "man"
    mv "lib", "libexec"
    prefix.install Dir["*"]
    bin.install_symlink "../rnammer", "../core-rnammer"
  end

  test do
    system "#{bin}/rnammer -v"
  end
end

__END__
diff --git a/rnammer b/rnammer
index b3382a9..a51c61d 100755
--- a/rnammer
+++ b/rnammer
@@ -32,10 +32,10 @@ my ($TEMP_WORKING_DIR , $multi,@MOL,%MOL_KEYS,$mol,$kingdom,%FLANK,$gff, $xml ,
 ## PROGRAM CONFIGURATION BEGIN
 
 # the path of the program
-my $INSTALL_PATH = "/usr/cbs/bio/src/rnammer-1.2";
+my $INSTALL_PATH = "HOMEBREW_PREFIX/opt/rnammer";
 
 # The library in which HMMs can be found
-my $HMM_LIBRARY = "$INSTALL_PATH/lib";
+my $HMM_LIBRARY = "$INSTALL_PATH/libexec";
 my $XML2GFF = "$INSTALL_PATH/xml2gff";
 my $XML2FSA = "$INSTALL_PATH/xml2fsa";
 
@@ -46,7 +46,10 @@ my $RNAMMER_CORE     = "$INSTALL_PATH/core-rnammer";
 chomp ( my $uname = `uname`);
 my $HMMSEARCH_BINARY;
 my $PERL;
-if ( $uname eq "Linux" ) {
+if (1) {
+	$HMMSEARCH_BINARY = "HOMEBREW_PREFIX/Cellar/hmmer2/2.3.2/bin/hmmsearch";
+	$PERL = "perl";
+} elsif ( $uname eq "Linux" ) {
 	$HMMSEARCH_BINARY = "/usr/cbs/bio/bin/linux64/hmmsearch";
 	$PERL = "/usr/bin/perl";
 } elsif ( $uname eq "IRIX64" ) {
