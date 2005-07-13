# All the provided in package systems:
KNOWN_TESTS = $(wildcard $(srcdir)/*.tcl)

# We only want to distriute these files
pkgdata_DATA = $(KNOWN_TESTS)

# The only way to add to the dist is using this one...
EXTRA_DIST = $(KNOWN_TESTS)

install-data-am:
#	mkdir -p $(libdir)/ibis$(VERSION)/tests
#	for s in $(KNOWN_TESTS); do cp $$s $(libdir)/ibis$(VERSION)/tests; done

