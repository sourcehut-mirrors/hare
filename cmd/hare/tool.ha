// SPDX-License-Identifier: GPL-3.0-only
// (c) Hare authors <https://harelang.org>

use errors;
use fmt;
use fs;
use getopt;
use os;
use os::exec;
use path;
use strings;

fn list_tools(paths: *strings::tokenizer) void = {
	for (const path => strings::next_token(paths)) {
		const dirs = match (os::iter(path)) {
		case let iter: *fs::iterator =>
			yield iter;
		case let err: fs::error =>
			fmt::printfln(
				"Error: Could not create iterator for {}: {}",
				path, fs::strerror(err))!;
			continue;
		};
		fmt::printfln("{}:", path)!;
		for (const file => fs::next(dirs)!) {
			const pb = path::init(path, file.name)!;
			const st = os::stat(path::string(&pb))!;
			const can_exec = ((st.mode & fs::mode::USER_X) |
				(st.mode & fs::mode::GROUP_X) |
				(st.mode & fs::mode::OTHER_X)) > 0;
			if (can_exec && len(file.name) > 5 && strings::sub(
					file.name, 0, 5) == "hare-") {
				const name = strings::sub(file.name, 5,
					strings::end);
				fmt::printfln("\t{}", name)!;
			};
		};
	};
};

fn tool(name: str, cmd: *getopt::command) (void | error) = {
	const toolpaths = os::tryenv("HARE_TOOLPATH", TOOLDIR);
	const paths = strings::tokenize(toolpaths, ":");

	for (const opt .. cmd.opts) {
		if (opt.0 == 'l') {
			list_tools(&paths);
			return;
		};
	};

	if (len(cmd.args) < 1) {
		getopt::printusage(os::stderr, name, cmd.help)!;
		os::exit(os::status::FAILURE);
	};
	const args: []str = [];
	if (len(cmd.args) > 1) {
		args = cmd.args[1..];
	};

	const tool = cmd.args[0];
	const name = fmt::asprintf("hare-{}", tool)!;
	defer free(name);

	for (const segment => strings::next_token(&paths)) {
		const path = path::init(segment)?;
		path::push(&path, name)?;

		const cmd = match (exec::cmd(path::string(&path), args...)) {
		case let cmd: exec::command =>
			yield cmd;
		case errors::noentry =>
			continue;
		case let err: exec::error =>
			return err;
		};

		const argv0 = fmt::asprintf("hare tool {}", tool)!;
		exec::setname(&cmd, argv0)!;
		const err = exec::exec(&cmd);
		fmt::fatalf("exec {}: {}", path::string(&path), exec::strerror(err));
	};

	fmt::fatalf("hare tool {}: tool not found", tool);
};
