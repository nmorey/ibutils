# All the provided in package systems:
KNOWN_IBNLS = $(wildcard $(srcdir)/*.ibnl)

# We only want to distriute these files
pkgdata_DATA = $(KNOWN_IBNLS)

# The only way to add to the dist is using this one...
EXTRA_DIST = $(KNOWN_IBNLS)

install-data-am:
	mkdir -p $(DESTDIR)/$(libdir)/ibdm$(VERSION)/ibnl
	for s in $(KNOWN_IBNLS); do cp $$s $(DESTDIR)/$(libdir)/ibdm$(VERSION)/ibnl/; done

