.PHONY = all clean createdir test install

# The directory of RE2 package
RE2_INSTALL_ROOT =
RE2_INC_DIR = $(RE2_INSTALL_ROOT)/usr/local/include
RE2_LIB_DIR = $(RE2_INSTALL_ROOT)/usr/local/lib
LUA_VERSION := 5.1

# the install dir of this package
PREFIX=/usr/local
LIB_TARGET_DIR=$(PREFIX)/lib
LUA_TARGET_DIR := $(PREFIX)/share/lua/$(LUA_VERSION)

CXXFLAGAS = -O3 -g -Wall
BUILD_CXXFLAGS = $(CXXFLAGAS) -fvisibility=hidden -I$(RE2_INC_DIR) -MMD
AR_BUILD_CXXFLAGS = -DBUILDING_LIB
SO_BUILD_CXXFLAGS = -DBUILDING_LIB -fPIC

CXX_SRC = re2_c.cxx
CXX_OBJ = ${CXX_SRC:.cxx=.o}
AR_OBJ = $(addprefix obj/lib/, $(CXX_OBJ))
SO_OBJ = $(addprefix obj/so/, $(CXX_OBJ))

AR_NAME = libre2c.a
SO_NAME = libre2c.so

BUILD_AR_DIR = obj/lib
BUILD_SO_DIR = obj/so

AR ?= ar
CXX ?= g++

all : $(BUILD_AR_DIR) $(BUILD_SO_DIR) $(AR_NAME) $(SO_NAME) $(RE2C_EX)

$(BUILD_AR_DIR):; mkdir -p $@
$(BUILD_SO_DIR):; mkdir -p $@

createdir :
	@if [ ! -d obj/lib ] ; then mkdir -p obj/lib ; fi && \
	if [ ! -d obj/so ] ; then mkdir -p obj/so ; fi

-include ar_dep.txt
-include so_dep.txt

$(AR_NAME) : $(AR_OBJ)
	$(AR) cru $@ $(AR_OBJ)

$(SO_NAME) : $(SO_OBJ)
	$(CXX) $(BUILD_CXXFLAGS) $(SO_BUILD_CXXFLAGS) $(SO_OBJ) -shared -L$(RE2_LIB_DIR) -lre2 -lpthread -o $@
	cat $(BUILD_SO_DIR)/*.d > so_dep.txt

$(AR_OBJ) : $(BUILD_AR_DIR)/%.o : %.cxx
	$(CXX) -c $(BUILD_CXXFLAGS) $(AR_BUILD_CXXFLAGS) $< -o $@
	cat $(BUILD_AR_DIR)/*.d > ar_dep.txt

$(SO_OBJ) : $(BUILD_SO_DIR)/%.o : %.cxx
	$(CXX) -c $(BUILD_CXXFLAGS) $(SO_BUILD_CXXFLAGS) $< -o $@

clean:
	rm -rf $(PROGRAM) ${BUILD_AR_DIR}/*.[od] ${BUILD_SO_DIR}/*.[od] *.[od] \
        *dep.txt $(AR_NAME) $(SO_NAME) $(RE2C_EX) obj/

test:
	export LD_LIBRARY_PATH=`pwd`:$(LD_LIBRARY_PATH):$(RE2_LIB_DIR); \
	luajit test.lua

install:
	install -D -m 755 $(AR_NAME) $(DESTDIR)/$(LIB_TARGET_DIR)/$(AR_NAME)
	install -D -m 755 $(SO_NAME) $(DESTDIR)/$(LIB_TARGET_DIR)/$(SO_NAME)
	install -D -m 664 lua-re2.lua $(DESTDIR)/$(LUA_TARGET_DIR)/lua-re2.lua
