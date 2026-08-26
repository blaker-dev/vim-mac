PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: all build install uninstall clean test run

all: build

build:
	swift build -c release --disable-sandbox

run: build
	./.build/release/vim-mac

install: build
	mkdir -p $(DESTDIR)$(BINDIR)
	install -m 755 .build/release/vim-mac $(DESTDIR)$(BINDIR)/vim-mac

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/vim-mac

clean:
	swift package clean
	rm -rf .build build
