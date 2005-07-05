
# We only want to distriute these files
pkgdata_DATA = $(wildcard $(srcdir)/*.topo) $(wildcard $(srcdir)/*.lst) 

# The only way to add to the dist is using this one...
EXTRA_DIST = $(pkgdata_DATA)

install-data-am:
	mkdir -p $(libdir)/ibdm$(VERSION)/ibnl
	for s in $(pkgdata_DATA); do cp $$s $(libdir)/ibdm$(VERSION)/ibnl/; done
