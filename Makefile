EM = $(EMSDK)/upstream/emscripten

ZIG_SRC = $(shell find . -path ./zig-cache -prune -o -type f -name "*.zig" -print)
ZIG_LIB = zig-out/lib/libzigmain.a

RES_DIR = res
RES = $(shell find $(RES_DIR) -name ".*" -prune -o -type f -print)

SHELL_FILE = src/shell.html

WWW_DIR = www
HTML = $(WWW_DIR)/index.html
WASM = $(HTML) $(WWW_DIR)/index.js $(WWW_DIR)/index.wasm
DATA = $(WWW_DIR)/data.data
DATA_JS = $(WWW_DIR)/data.js

build: $(WASM) $(DATA) $(DATA_JS)

$(WASM): $(ZIG_LIB)
	$(EM)/emcc \
		$(ZIG_LIB) \
		-o $(HTML) \
		--shell-file $(SHELL_FILE) \
		-sUSE_SDL=2 \
		-sUSE_SDL_GFX=2 \
		-sUSE_SDL_IMAGE=2 -sSDL2_IMAGE_FORMATS='["bmp","png"]' \
		-sUSE_SDL_MIXER=2 -sSDL2_MIXER_FORMATS='["mp3"]' \
		-sFORCE_FILESYSTEM \
		-sALLOW_MEMORY_GROWTH=1 \
		-sASSERTIONS=2 -sSAFE_HEAP=1 -g \
		-O0

$(ZIG_LIB): $(ZIG_SRC)
	zig build

$(DATA) $(DATA_JS): $(RES)
	$(EM)/tools/file_packager \
		$(DATA) \
		--preload $(RES_DIR) \
		--exclude $(RES_DIR)/.* \
		--js-output=$(DATA_JS) \
		--use-preload-plugins \
		--no-node

server: build
	python3 -m http.server --directory $(WWW_DIR)

archive: build
	zip -r archive.zip $(WWW_DIR)

clean:
	rm -rf zig-cache
	rm -rf zig-out
	rm -rf $(WWW_DIR)/*
