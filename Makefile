VERSION = 2.3.0
INSTALL = /usr/bin/install -c

# Installation directories
prefix = ${DESTDIR}/usr
exec_prefix = ${prefix}
mandir = ${prefix}/share/man/man1
bindir = ${exec_prefix}/bin
etcdir = ${DESTDIR}/etc

all:

clean:

install:
	$(INSTALL) -d -m 755 $(bindir)
	$(INSTALL) -m 755 -o 0 abcde $(bindir)
	$(INSTALL) -m 755 -o 0 cddb-tool $(bindir)
	$(INSTALL) -d -m 755 $(mandir)
	$(INSTALL) -m 644 -o 0 abcde.1 $(mandir)
	$(INSTALL) -m 644 -o 0 cddb-tool.1 $(mandir)
	$(INSTALL) -d -m 755 $(etcdir)
	$(INSTALL) -m 644 -o 0 abcde.conf $(etcdir)

tarball:
	@cd .. && tar czvf abcde_$(VERSION).orig.tar.gz \
		abcde-$(VERSION)/{Makefile,COPYING,README,TODO,FAQ,abcde,abcde.1,abcde.conf,changelog,cddb-tool,cddb-tool.1,examples/}

