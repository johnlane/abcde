abcde_version = abcde-2.8
INSTALL = /usr/bin/install -c

prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
sysconfdir = /etc
datarootdir = $(prefix)/share
docdir = $(datarootdir)/doc/$(abcde_version)
mandir = $(datarootdir)/man
DESTDIR =

all:

clean:

install:
	$(INSTALL) -d -m 755 $(DESTDIR)$(bindir)
	$(INSTALL) -m 755 abcde cddb-tool abcde-musicbrainz-tool $(DESTDIR)$(bindir)
	$(INSTALL) -d -m 755 $(DESTDIR)$(sysconfdir)
	$(INSTALL) -m 644 abcde.conf $(DESTDIR)$(sysconfdir)
	$(INSTALL) -d -m 755 $(DESTDIR)$(docdir)
	$(INSTALL) -m 644 changelog COPYING FAQ README $(DESTDIR)$(docdir)
	$(INSTALL) -d -m 755 $(DESTDIR)$(mandir)/man1
	$(INSTALL) -m 644 abcde.1 cddb-tool.1 $(DESTDIR)$(mandir)/man1

uninstall:

	-rm -v \
	$(DESTDIR)$(bindir)/abcde \
	$(DESTDIR)$(bindir)/cddb-tool \
	$(DESTDIR)$(bindir)/abcde-musicbrainz-tool \
	$(DESTDIR)$(sysconfdir)/abcde.conf \
	$(DESTDIR)$(docdir)/changelog \
	$(DESTDIR)$(docdir)/COPYING \
	$(DESTDIR)$(docdir)/FAQ \
	$(DESTDIR)$(docdir)/README \
	$(DESTDIR)$(mandir)/man1/abcde.1 \
	$(DESTDIR)$(mandir)/man1/cddb-tool.1
