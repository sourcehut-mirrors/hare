# install locations
PREFIX = /boot/home/config/non-packaged
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/man
SRCDIR = $(PREFIX)/src
STDLIB = $(SRCDIR)/hare/stdlib
LIBEXECDIR = $(PREFIX)/libexec
TOOLDIR = $(LIBEXECDIR)/hare

# variables used during build
PLATFORM = haiku
ARCH = x86_64
HAREFLAGS =
HARECFLAGS = -m ''
QBEFLAGS =
ASFLAGS =
LDLINKFLAGS = -z noexecstack

# commands used by the build script
HAREC = harec
QBE = qbe
AS = as
LD = cc
SCDOC = scdoc

# build locations
HARECACHE = .cache
BINOUT = .bin

# variables that will be embedded in the binary with -D definitions
HAREPATH = $(SRCDIR)/hare/stdlib:$(SRCDIR)/hare/third-party
VERSION=$$(./scripts/version)

# for cross-compilation, modify the variables below
AARCH64_AS=as
AARCH64_CC=cc
AARCH64_LD=cc

RISCV64_AS=as
RISCV64_CC=cc
RISCV64_LD=cc

X86_64_AS=as
X86_64_CC=cc
X86_64_LD=cc
