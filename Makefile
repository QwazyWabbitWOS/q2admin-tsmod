# q2admin.so linux makefile

# This builds in the native mode of the current OS by default.

# Note that you might need to install the 32-bit libc package
# if it isn't already installed on your platform.
# Examples:
# sudo apt-get install ia32-libs
# sudo apt-get install libc6-dev-i386
# On Ubuntu use sudo apt install libc6-dev-i386
# On 64-bit OS use the command: setarch i386 make all
# to obtain the 32-bit binary DLL on 64-bit Linux.

.DEFAULT_GOAL := game

#this nice line comes from the linux kernel makefile
ARCH := $(shell uname -m | sed -e s/i.86/i386/ -e s/sun4u/sparc64/ -e s/arm.*/arm/ -e s/sa110/arm/ -e s/alpha/axp/)

# On 64-bit OS use the command: setarch i386 make all
# to obtain the 32-bit binary DLL on 64-bit Linux.

CC = gcc -std=c11 -Wall

CFLAGS =-O2 -fPIC -DARCH="$(ARCH)" -DSTDC_HEADERS
LDFLAGS = -ldl -lm -shared

ifeq ($(ARCH),i386)
CFLAGS +=-m32 -I/usr/include
endif

# Msys2 on Windows for MinGW
ifeq ($(shell uname -o),Msys)
LDFLAGS += -lregex
endif

# flavors of Linux
ifeq ($(shell uname),Linux)
CFLAGS += -DLINUX
LIBTOOL = ldd
endif

# OS X wants to be Linux and FreeBSD too.
ifeq ($(shell uname),Darwin)
CFLAGS += -DLINUX
LIBTOOL = otool
endif

SHLIBEXT=so
#set position independent code
SHLIBCFLAGS=-fPIC

# Build directory
BUILD_DIR = build$(ARCH)
# Ensure build directory exists
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# zb_clib is used by MinGW. See: Q2ADMINCLIB
# List of source files
GAME_SRCS = \
	g_main.c \
	zb_ban.c \
	zb_checkvar.c \
	zb_cmd.c \
	zb_clib.c \
	zb_disable.c \
	zb_flood.c \
	zb_init.c \
	zb_log.c \
	zb_lrcon.c \
	zb_msgqueue.c \
	zb_spawn.c \
	zb_util.c \
	zb_vote.c \
	zb_zbot.c \
	zb_zbotcheck.c

GAME_OBJS = $(GAME_SRCS:%.c=$(BUILD_DIR)/%.o)

# Pattern rule to place objects in build directory
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) $(SHLIBCFLAGS) -MMD -MP -MF $(@:.o=.d) -o $@ -c $<

-include $(GAME_OBJS:.o=.d)

# Build all object files that are out-of-date
game: $(GAME_OBJS) game$(ARCH).$(SHLIBEXT)

# Main target: depends on all object files
game$(ARCH).$(SHLIBEXT) : $(GAME_OBJS)
	$(CC) $(CFLAGS) -shared -o $@ $(GAME_OBJS) -ldl -lm
	$(LIBTOOL) -r $@
	file $@

# Build everything (always rebuild all objects and the shared library)
all:
	$(MAKE) clean
	$(MAKE) $(BUILD_DIR)
	$(MAKE) $(GAME_OBJS)
	$(MAKE) game$(ARCH).$(SHLIBEXT)


clean:
	rm -rf $(BUILD_DIR)
