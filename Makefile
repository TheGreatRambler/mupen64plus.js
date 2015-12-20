
ROMS_DIR ?= roms
INPUT_ROM ?= m64p_test_rom.v64
GAMES_DIR ?= games
OUTPUT_DIR ?= $(abspath $(GAMES_DIR)/$(INPUT_ROM))

CORE ?= mupen64plus-core
CORE_DIR = $(CORE)/projects/unix
CORE_LIB = libmupen64plus.so.2.js

AUDIO ?= mupen64plus-audio-sdl
AUDIO_DIR = $(AUDIO)/projects/unix/
AUDIO_LIB = $(AUDIO).js


VIDEO ?= mupen64plus-video-glide64mk2
VIDEO_DIR = $(VIDEO)/projects/unix
VIDEO_LIB = $(VIDEO).js

INPUT ?= mupen64plus-input-sdl
INPUT_DIR = $(INPUT)/projects/unix
INPUT_LIB = $(INPUT).js

RSP ?= mupen64plus-rsp-hle
RSP_DIR = $(RSP)/projects/unix
RSP_LIB = $(RSP).js

TARGET ?= mupen64plus
BIN_DIR = mupen64plus-ui-console/projects/unix
PLUGINS_DIR = $(BIN_DIR)/plugins
OUTPUT_ROMS_DIR = $(BIN_DIR)/$(ROMS_DIR)
TARGET_LIB = $(TARGET).js


PLUGINS = $(PLUGINS_DIR)/$(CORE_LIB) \
	$(PLUGINS_DIR)/$(AUDIO_LIB) \
	$(PLUGINS_DIR)/$(VIDEO_LIB) \
	$(PLUGINS_DIR)/$(INPUT_LIB) \
	$(PLUGINS_DIR)/$(RSP_LIB)


OPT_LEVEL = -O0
DEBUG_LEVEL = -g2

#MEMORY = 402653184
MEMORY = 268435456
#MEMORY = 134217728

ifeq ($(config), debug)

OPT_LEVEL = -O0
DEBUG_LEVEL = -g2 -s ASSERTIONS=1

else ifeq ($(config), release)

OPT_LEVEL = -Oz
#OPT_LEVEL = -Oz -s OUTLINING_LIMIT=10000
DEBUG_LEVEL =

else

$(error Specify a build configuration, eg: make config=dev)

endif


all: $(OUTPUT_DIR)/$(TARGET_LIB)

$(OUTPUT_DIR)/$(TARGET_LIB) : $(BIN_DIR)/$(TARGET_LIB)
	(cp -r $(BIN_DIR)/*  $(OUTPUT_DIR) )



#$(PLUGINS_DIR)/%.js : %/projects/unix/%.js
#	cp "$<" "$@"

# libmupen64plus.so.2 deviates from standard naming
$(PLUGINS_DIR)/$(CORE_LIB) : $(CORE_DIR)/$(CORE_LIB)
	mkdir -p $(PLUGINS_DIR)
	cp "$<" "$@"

$(PLUGINS_DIR)/$(AUDIO_LIB) : $(AUDIO_DIR)/$(AUDIO_LIB)
	mkdir -p $(PLUGINS_DIR)
	cp "$<" "$@"

$(PLUGINS_DIR)/$(VIDEO_LIB) : $(VIDEO_DIR)/$(VIDEO_LIB)
	mkdir -p $(PLUGINS_DIR)
	cp "$<" "$@"

$(PLUGINS_DIR)/$(INPUT_LIB) : $(INPUT_DIR)/$(INPUT_LIB)
	mkdir -p $(PLUGINS_DIR)
	cp "$<" "$@"

$(PLUGINS_DIR)/$(RSP_LIB) : $(RSP_DIR)/$(RSP_LIB)
	mkdir -p $(PLUGINS_DIR)
	cp "$<" "$@"

$(OUTPUT_ROMS_DIR)/$(INPUT_ROM) : $(ROMS_DIR)/$(INPUT_ROM)
	mkdir -p $(OUTPUT_ROMS_DIR)
	rm -f $(OUTPUT_ROMS_DIR)/*
	cp "$<" "$@"

$(OUTPUT_DIR) :
	#Creating output directory
	mkdir -p $(OUTPUT_DIR)



$(BIN_DIR)/$(TARGET_LIB) : $(PLUGINS) $(OUTPUT_ROMS_DIR)/$(INPUT_ROM) $(OUTPUT_DIR)
	# building core lib
	cd $(BIN_DIR) && \
	rm -fr _obj && \
	EMCC_FORCE_STDLIBS=1 emmake make \
		TARGET=index.html \
		UNAME=Linux \
		EMSCRIPTEN=1 \
		EXEEXT=".html" \
		USE_GLES=1 NO_ASM=1 \
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) \
		-s MAIN_MODULE=1 --preload-file plugins \
		--preload-file data  --preload-file roms \
		--preload-file Glide64mk2.ini \
		--preload-file InputAutoCfg.ini \
		-s TOTAL_MEMORY=$(MEMORY) \
		-s USE_ZLIB=1 -s USE_SDL=2 -s USE_LIBPNG=1 \
		-DEMSCRIPTEN=1 -DINPUT_ROM=$(INPUT_ROM)" \
		all
	(cp $(BIN_DIR)/customIndex.html  $(BIN_DIR)/index.html )

$(CORE_DIR)/$(CORE_LIB) :
	cd $(CORE_DIR) && \
	emmake make \
		UNAME=Linux \
		TARGET="libmupen64plus.so.2.js" \
		SONAME="" \
		USE_GLES=1 NO_ASM=1 \
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s SIDE_MODULE=1  -DEMSCRIPTEN=1" \
		all

$(AUDIO_DIR)/$(AUDIO_LIB) :
	cd $(AUDIO_DIR) && \
	emmake make \
	UNAME="Linux" \
		EMSCRIPTEN=1 \
		NO_SRC=1 \
		NO_SPEEX=1 \
		NO_OSS=1 \
		SO_EXTENSION="js" \
		USE_GLES=1 NO_ASM=1 \
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s SIDE_MODULE=1 -DEMSCRIPTEN=1 -DNO_FILTER_THREAD=1" \
		all

$(VIDEO_DIR)/$(VIDEO_LIB) :
	cd $(VIDEO_DIR) && \
	emmake make \
		USE_FRAMESKIPPER=1 \
		EMSCRIPTEN=1 \
		SO_EXTENSION="js" \
		USE_GLES=1 NO_ASM=1 \
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		LOADLIBES="../../../boost_1_59_0/stage/lib/libboost_filesystem.a ../../../boost_1_59_0/stage/lib/libboost_system.a" \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s SIDE_MODULE=1 -DUSE_FRAMESKIPPER=1\
		-I../../../boost_1_59_0 \
		-DEMSCRIPTEN=1 -DNO_FILTER_THREAD=1" \
		all

$(INPUT_DIR)/$(INPUT_LIB) :
	cd $(INPUT_DIR) && \
	emmake make \
		UNAME="Linux" \
		EMSCRIPTEN=1 \
		SO_EXTENSION="js" \
		USE_GLES=1 NO_ASM=1 \
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s SIDE_MODULE=1 -I../../../boost_1_59_0 -DEMSCRIPTEN=1 -DNO_FILTER_THREAD=1" \
		all

$(RSP_DIR)/$(RSP_LIB) :
	cd $(RSP_DIR)&& \
	emmake make \
		UNAME=Linux \
		EMSCRIPTEN=1 \
		SO_EXTENSION="js" \
		USE_GLES=1 NO_ASM=1 NO_OSS=1 NO_SRC=1 NO_SPEEX=1\
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s SIDE_MODULE=1 -DEMSCRIPTEN=1 -DVIDEO_HLE_ALLOWED=1" \
		all





clean:
	rm -f $(PLUGINS_DIR)/*
	rm -f $(OUTPUT_ROMS_DIR)/*
	cd $(BIN_DIR) && \
	EMCC_FORCE_STDLIBS=1 emmake make \
		UNAME=Linux \
		EMSCRIPTEN=1 \
		EXEEXT=".html" \
		USE_GLES=1 NO_ASM=1 \
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s MAIN_MODULE=1 --preload-file plugins --preload-file data  --preload-file roms --preload-file Glide64mk2.ini --preload-file InputAutoCfg.ini -s TOTAL_MEMORY=$(MEMORY) -s USE_ZLIB=1 -s USE_SDL=2 -s USE_LIBPNG=1 -DEMSCRIPTEN=1" \
		clean
	rm -f -r $(BIN_DIR)/_obj
	rm -f $(BIN_DIR)/$(TARGET_LIB)
	cd $(AUDIO_DIR) && \
	emmake make \
	UNAME="Linux" \
		EMSCRIPTEN=1 \
		NO_SRC=1 \
		NO_SPEEX=1 \
		NO_OSS=1 \
		SO_EXTENSION="js" \
		USE_GLES=1 NO_ASM=1 \
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s SIDE_MODULE=1 -DEMSCRIPTEN=1 -DNO_FILTER_THREAD=1" \
		clean
	cd $(VIDEO_DIR) && \
	emmake make \
		UNAME="Linux" \
		EMSCRIPTEN=1 \
		SO_EXTENSION="js" \
		USE_GLES=1 NO_ASM=1 \
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		LOADLIBES="../../../boost_1_59_0/stage/lib/libboost_filesystem.a ../../../boost_1_59_0/stage/lib/libboost_system.a" \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s SIDE_MODULE=1 -I../../../boost_1_59_0 -DEMSCRIPTEN=1 -DNO_FILTER_THREAD=1 -DUSE_FRAMESKIPPER=1" \
		clean
	cd $(INPUT_DIR) && \
	emmake make \
		UNAME="Linux" \
		EMSCRIPTEN=1 \
		SO_EXTENSION="js" \
		USE_GLES=1 NO_ASM=1 \
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s SIDE_MODULE=1 -I../../../boost_1_59_0 -DEMSCRIPTEN=1 -DNO_FILTER_THREAD=1" \
		clean
	cd $(RSP_DIR)&& \
	emmake make \
		UNAME=Linux \
		EMSCRIPTEN=1 \
		SO_EXTENSION="js" \
		USE_GLES=1 NO_ASM=1 NO_OSS=1 NO_SRC=1 NO_SPEEX=1\
		ZLIB_CFLAGS="-s USE_ZLIB=1" \
		PKG_CONFIG="" \
		LIBPNG_CFLAGS="-s USE_LIBPNG=1" \
		SDL_CFLAGS="-s USE_SDL=2" \
		FREETYPE2_CFLAGS="-s USE_FREETYPE=1" \
		GL_CFLAGS="" \
		GLU_CFLAGS="" \
		V=1 \
		OPTFLAGS="$(OPT_LEVEL) $(DEBUG_LEVEL) -s SIDE_MODULE=1 -DEMSCRIPTEN=1 -DVIDEO_HLE_ALLOWED=1" \
		clean
