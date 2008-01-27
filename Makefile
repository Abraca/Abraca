include config.mk

DESTDIR =

SOURCES = \
	src/abraca.vala \
	src/config.vala \
	src/collections_tree.vala \
	src/filter_tree.vala \
	src/main_hpaned.vala \
	src/main_window.vala \
	src/menubar.vala \
	src/playlist_tree.vala \
	src/right_hpaned.vala \
	src/toolbar.vala \
	src/client.vala \
	src/server_browser.vala \
	src/dragdroptarget.vala \

PACKAGES = $(addprefix --pkg ,gtk+-2.0 xmms2-client-glib)

build/abraca: $(SOURCES)
	@if [ ! -d build ]; then \
		mkdir build; \
	fi
	$(VALAC) --vapidir=vapi --save-temps -d build $(PACKAGES) $^ -o abraca

install: build/abraca
	install -m 755 -D build/abraca $(DESTDIR)$(PREFIX)/bin/abraca
	install -m 644 -D data/abraca.desktop $(DESTDIR)$(PREFIX)/share/applications/abraca.desktop
	install -m 644 -D data/abraca-128.png $(DESTDIR)$(PREFIX)/share/pixmaps/abraca-128.png
	install -m 644 -D data/abraca.svg $(DESTDIR)$(PREFIX)/share/pixmaps/abraca.svg

clean:
	rm -f build/abraca
