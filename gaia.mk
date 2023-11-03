IPCGEN=ipcgen
PROTOS=/usr/share/mercury/proto
IPCFLAGS=-Nrt:: -Rrt::ipc

$(BINOUT)/gaia-test: protos
	HARECFLAGS="-T" $(BINOUT)/hare build \
		   -T^+x86_64+gaia+test -o $@ \
		   cmd/gaia-test/
.PHONY: $(BINOUT)/gaia-test

$(HARECACHE)/rt/rt-gaia.ssa: protos
.PHONY: protos

rt/dev/clock_gen.ha: $(PROTOS)/dev/clock.ipc
	@printf 'IPCGEN %s\n' "$@"
	@mkdir -p "$$(dirname $@)"
	@$(IPCGEN) $(IPCFLAGS) \
		client <$(PROTOS)/dev/clock.ipc >$@
protos: rt/dev/clock_gen.ha

rt/dev/console_gen.ha: $(PROTOS)/dev/console.ipc
	@printf 'IPCGEN %s\n' "$@"
	@mkdir -p "$$(dirname $@)"
	@$(IPCGEN) $(IPCFLAGS) \
		-I$(PROTOS)/io/file.ipc \
		-I$(PROTOS)/meta/refcount.ipc \
		client <$(PROTOS)/dev/console.ipc >$@
protos: rt/dev/console_gen.ha

rt/errors/errors_gen.ha: $(PROTOS)/errors/errors.ipc
	@printf 'IPCGEN %s\n' "$@"
	@mkdir -p "$$(dirname $@)"
	@$(IPCGEN) $(IPCFLAGS) \
		client <$(PROTOS)/errors/errors.ipc >$@
protos: rt/errors/errors_gen.ha

rt/fs/fs_gen.ha: \
		$(PROTOS)/fs/fs.ipc \
		$(PROTOS)/errors/errors.ipc \
		$(PROTOS)/io/file.ipc \
		$(PROTOS)/meta/refcount.ipc
	@printf 'IPCGEN %s\n' "$@"
	@mkdir -p "$$(dirname $@)"
	@$(IPCGEN) $(IPCFLAGS) \
		-I$(PROTOS)/errors/errors.ipc \
		-I$(PROTOS)/io/file.ipc \
		-I$(PROTOS)/meta/refcount.ipc \
		client <$(PROTOS)/fs/fs.ipc >$@
protos: rt/fs/fs_gen.ha

rt/io/file_gen.ha: $(PROTOS)/io/file.ipc $(PROTOS)/meta/refcount.ipc
	@printf 'IPCGEN %s\n' "$@"
	@mkdir -p "$$(dirname $@)"
	@$(IPCGEN) $(IPCFLAGS) \
		-I$(PROTOS)/meta/refcount.ipc \
		client <$(PROTOS)/io/file.ipc >$@
protos: rt/io/file_gen.ha

rt/meta/refcount_gen.ha: $(PROTOS)/meta/refcount.ipc
	@printf 'IPCGEN %s\n' "$@"
	@mkdir -p "$$(dirname $@)"
	@$(IPCGEN) $(IPCFLAGS) \
		client <$(PROTOS)/meta/refcount.ipc >$@
protos: rt/meta/refcount_gen.ha

rt/sys/mman_gen.ha: $(PROTOS)/sys/mman.ipc
	@printf 'IPCGEN %s\n' "$@"
	@mkdir -p "$$(dirname $@)"
	@$(IPCGEN) $(IPCFLAGS) \
		client <$(PROTOS)/sys/mman.ipc >$@
protos: rt/sys/mman_gen.ha

rt/sys/proc_gen.ha: \
		$(PROTOS)/sys/proc.ipc \
		$(PROTOS)/sys/mman.ipc \
		$(PROTOS)/io/file.ipc \
		$(PROTOS)/meta/refcount.ipc
	@printf 'IPCGEN %s\n' "$@"
	@mkdir -p "$$(dirname $@)"
	@$(IPCGEN) $(IPCFLAGS) \
		-I$(PROTOS)/sys/mman.ipc \
		-I$(PROTOS)/io/file.ipc \
		-I$(PROTOS)/meta/refcount.ipc \
		client <$(PROTOS)/sys/proc.ipc >$@
protos: rt/sys/proc_gen.ha

rt/sys/pipe_gen.ha: \
		$(PROTOS)/sys/pipe.ipc \
		$(PROTOS)/io/file.ipc \
		$(PROTOS)/meta/refcount.ipc
	@printf 'IPCGEN %s\n' "$@"
	@mkdir -p "$$(dirname $@)"
	@$(IPCGEN) $(IPCFLAGS) \
		-I$(PROTOS)/io/file.ipc \
		-I$(PROTOS)/meta/refcount.ipc \
		client <$(PROTOS)/sys/pipe.ipc >$@
protos: rt/sys/pipe_gen.ha

clean-protos:
	rm -rf rt/io rt/meta rt/sys rt/dev rt/errors
