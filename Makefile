DESTDIR =
PREFIX ?= /usr/local

SOURCES = \
	src/abraca.vala \
	src/collections_tree.vala \
	src/filter_tree.vala \
	src/main_hpaned.vala \
	src/main_window.vala \
	src/menubar.vala \
	src/playlist_tree.vala \
	src/right_hpaned.vala \
	src/toolbar.vala \


build/abraca: $(SOURCES)
	@if [ ! -d build ]; then \
		mkdir build; \
	fi
	valac -d build --pkg gtk+-2.0 $^ -o abraca

install: build/abraca
	install -m 755 -D build/abraca $(DESTDIR)$(PREFIX)/bin/abraca
	install -m 644 -D data/abraca.desktop $(DESTDIR)$(PREFIX)/share/applications/abraca.desktop

clean:
	rm -f build/abraca
