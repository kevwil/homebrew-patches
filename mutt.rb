class Mutt < Formula
  desc "Mongrel of mail user agents (part elm, pine, mush, mh, etc.)"
  homepage "http://www.mutt.org/"
  url "https://bitbucket.org/mutt/mutt/downloads/mutt-1.6.2.tar.gz"
  mirror "ftp://ftp.mutt.org/pub/mutt/mutt-1.6.2.tar.gz"
  sha256 "c5d02ef06486cdf04f9eeb9e9d7994890d8dfa7f47e7bfeb53a2a67da2ac1d8e"

  head do
    url "https://dev.mutt.org/hg/mutt#default", :using => :hg

    resource "html" do
      url "https://dev.mutt.org/doc/manual.html", :using => :nounzip
    end
  end

  #unless Tab.for_name('signing-party').with? 'rename-pgpring'
  #  conflicts_with 'signing-party',
  #    :because => 'mutt installs a private copy of pgpring'
  #end

  conflicts_with "tin",
    :because => "both install mmdf.5 and mbox.5 man pages"

  option "with-debug", "Build with debug option enabled"
  option "with-trash-patch", "Apply trash folder patch"
  option "with-sidebar-patch", "Apply sidebar patch"
  option "with-s-lang", "Build against slang instead of ncurses"
  #option "with-ignore-thread-patch", "Apply ignore-thread patch"
  #option "with-pgp-verbose-mime-patch", "Apply PGP verbose mime patch"
  option "with-confirm-attachment-patch", "Apply confirm attachment patch"

  depends_on "autoconf" => :build
  depends_on "automake" => :build

  depends_on "openssl"
  depends_on "tokyo-cabinet"
  depends_on "gettext" => :optional
  depends_on "gpgme" => :optional
  depends_on "libidn" => :optional
  depends_on 's-lang' => :optional

  patch do
    url "http://ftp.openbsd.org/pub/OpenBSD/distfiles/mutt/trashfolder-1.6.0.diff.gz"
    sha1 "b779c6df61a77f3069139aad8562b4a47c8eed8ab5b8f5681742a1c2eaa190b8"
  end if build.with? "trash-patch"

  patch do
    url "http://ftp.openbsd.org/pub/OpenBSD/distfiles/mutt/sidebar-1.6.0.diff.gz"
    sha256 "63b6b28d7008b6d52bd98151547b052251cd4bc87e467e47ffebe372dfe7155b"
  end if build.with? "sidebar-patch"

  # original source for this went missing, patch sourced from Arch at
  # https://aur.archlinux.org/packages/mutt-ignore-thread/
  #patch do
  #  url "https://gist.githubusercontent.com/mistydemeo/5522742/raw/1439cc157ab673dc8061784829eea267cd736624/ignore-thread-1.5.21.patch"
  #  sha1 "dbcf5de46a559bca425028a18da0a63d34f722d3"
  #end if build.with? "ignore-thread-patch"

  #patch do
  #  url "http://patch-tracker.debian.org/patch/series/dl/mutt/1.5.21-6.2+deb7u1/features-old/patch-1.5.4.vk.pgp_verbose_mime"
  #  sha1 "a436f967aa46663cfc9b8933a6499ca165ec0a21"
  #end if build.with? "pgp-verbose-mime-patch"

  patch do
    url "https://gist.githubusercontent.com/tlvince/5741641/raw/c926ca307dc97727c2bd88a84dcb0d7ac3bb4bf5/mutt-attach.patch"
    sha256 "da2c9e54a5426019b84837faef18cc51e174108f07dc7ec15968ca732880cb14"
  end if build.with? "confirm-attachment-patch"


  def install
    user_admin = Etc.getgrnam("admin").mem.include?(ENV["USER"])
    
    args = %W[
      --disable-dependency-tracking
      --disable-warnings
      --prefix=#{prefix}
      --with-ssl=#{Formula['openssl'].opt_prefix}
      --with-sasl
      --with-gss
      --enable-imap
      --enable-smtp
      --enable-pop
      --enable-hcache
      --with-tokyocabinet
    ]
    
    # This is just a trick to keep 'make install' from trying
    # to chgrp the mutt_dotlock file (which we can't do if
    # we're running as an unprivileged user)
    args << "--with-homespool=.mbox" unless user_admin
    
    args << "--disable-nls" if build.without? "gettext"
    args << "--enable-gpgme" if build.with? "gpgme"
    args << "--with-slang" if build.with? "s-lang"

    if build.with? "debug"
      args << "--enable-debug"
    else
      args << "--disable-debug"
    end


    system "./prepare", *args
    system "make"
    
    # This permits the `mutt_dotlock` file to be installed under a group
    # that isn't `mail`.
    # https://github.com/Homebrew/homebrew/issues/45400
    if user_admin
      inreplace "Makefile", /^DOTLOCK_GROUP =.*$/, "DOTLOCK_GROUP = admin"
    end
    
    system "make", "install"
    doc.install resource("html") if build.head?
  end

  test do
    system bin/"mutt", "-D"
  end
end
