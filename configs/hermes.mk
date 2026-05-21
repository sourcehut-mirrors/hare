# install locations
PREFIX = /usr/local
BINDIR = $(PREFIX)/bin
SHAREDIR = $(PREFIX)/share
MANDIR = $(SHAREDIR)/man
SRCDIR = $(PREFIX)/src
STDLIB = $(SRCDIR)/hare/stdlib
LIBEXECDIR = $(PREFIX)/libexec
TOOLDIR = $(LIBEXECDIR)/hare

# variables used during build
PLATFORM = hermes
ARCH = x86_64
HAREFLAGS =
HARECFLAGS =
QBEFLAGS =
ASFLAGS =
LDLINKFLAGS = --gc-sections

# commands used by the build script
HAREC = harec
QBE = qbe
AS = as
LD = ld
SCDOC = scdoc
GENPROTO = artemis-genproto

# Path to artemis-protos installation
PROTOS = $(SHAREDIR)/artemis/protos

# build locations
HARECACHE = .cache
BINOUT = .bin

# variables that will be embedded in the binary with -D definitions
HAREPATH = $(SRCDIR)/hare/stdlib:$(SRCDIR)/hare/third-party
VERSION=$$(./scripts/version)

# For cross-compilation, modify the variables below
AARCH64_AS=aarch64-alpine-linux-musl-as
AARCH64_CC=aarch64-alpine-linux-musl-cc
AARCH64_LD=aarch64-alpine-linux-musl-ld

RISCV64_AS=riscv64-alpine-linux-musl-as
RISCV64_CC=riscv64-alpine-linux-musl-cc
RISCV64_LD=riscv64-alpine-linux-musl-ld

X86_64_AS=as
X86_64_CC=cc
X86_64_LD=ld
