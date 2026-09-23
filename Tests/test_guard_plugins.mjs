// Run installed plugin code with mocked host APIs. No agent, shell command, or network request runs.
import assert from "node:assert/strict";
import childProcess from "node:child_process";
import { stripTypeScriptTypes, syncBuiltinESMExports } from "node:module";
import { mkdtemp, readFile, writeFile, rm, realpath } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const home = await realpath(await mkdtemp(path.join(tmpdir(), "termosaic-plugin-test-")));
const realSpawn = childProcess.spawnSync;
const env = { ...process.env, PYTHONDONTWRITEBYTECODE: "1", DANGER_GUARD_SILENT: "1", DANGER_GUARD_ASK: "0" };
let count = 0;
function check(value, message) { assert.ok(value, message); count++; }
try {
	for (const client of ["pi", "opencode"]) {
		const result = realSpawn("/usr/bin/python3", ["-B", path.join(root, "AgentGuard/manage.py"), "install", client, "--home", home], { env, encoding: "utf8" });
		assert.equal(result.status, 0, result.stderr);
	}
	const plugin = await import(pathToFileURL(path.join(home, ".config/opencode/plugin/bypass-yes-opencode.js")));
	const before = (await plugin.BypassYesGuard({ directory: root }))["tool.execute.before"];
	// Python is only classifying strings. Patch env to keep failure tests quiet.
	childProcess.spawnSync = (command, args, options) => realSpawn(command, args, { ...options, env });
	syncBuiltinESMExports();
	await before({ tool: "read" }, {});
	await before({ tool: "bash" }, { args: { command: "git status" } });
	count += 2;
	for (const command of ["git reset --hard HEAD", "rm -rf /", ""]) {
		await assert.rejects(before({ tool: "bash" }, { args: { command } }), /命令守卫/);
		count++;
	}
	for (const result of [null, { status: 1 }, { status: null, error: new Error("timeout") },
		{ status: 0, stdout: "" }, { status: 0, stdout: "bad-json" },
		{ status: 0, stdout: "null" }, { status: 0, stdout: '{"level":"allowlist"}' },
		{ status: 0, stdout: '{"level":"warn"}' }]) {
		childProcess.spawnSync = () => result;
		syncBuiltinESMExports();
		await assert.rejects(before({ tool: "bash" }, { args: { command: "git status" } }), /命令守卫/);
		count++;
	}
	childProcess.spawnSync = () => { throw new Error("bridge failed"); };
	syncBuiltinESMExports();
	await assert.rejects(before({ tool: "bash" }, { args: { command: "git status" } }), /命令守卫/);
	count++;
	childProcess.spawnSync = realSpawn;
	syncBuiltinESMExports();

	// Only the pi SDK's tool-name helper is substituted. Strip types using existing Node.
	const piDir = path.join(home, ".pi/agent/extensions");
	let piSource = stripTypeScriptTypes(await readFile(path.join(piDir, "bypass-yes-guard.ts"), "utf8"));
	piSource = piSource.replace('import { isToolCallEventType } from "@earendil-works/pi-coding-agent";',
		'const isToolCallEventType = (name, event) => event.toolName === name;');
	await writeFile(path.join(piDir, "guard-test.mjs"), piSource);
	const piModule = await import(pathToFileURL(path.join(piDir, "guard-test.mjs")));
	let handler;
	const api = {
		on(event, callback) { assert.equal(event, "tool_call"); handler = callback; },
		exec(command, args, options) {
			const result = realSpawn(command, args, { ...options, encoding: "utf8", env });
			return { code: result.status, stdout: result.stdout };
		},
	};
	piModule.default(api);
	const event = command => ({ toolName: "bash", input: { command } });
	const ctx = { cwd: root, hasUI: true, ui: { confirm() { throw new Error("Must not prompt"); } } };
	check(await handler({ toolName: "read" }, ctx) === undefined, "pi skips non-shell tools");
	check(await handler(event("git status"), ctx) === undefined, "pi permits normal calls");
	for (const command of ["git reset --hard HEAD", "rm -rf /", ""]) {
		check((await handler(event(command), ctx)).block === true, "pi blocks dangerous/invalid input");
	}
	for (const result of [null, { code: 1 }, { code: 0, stdout: "" }, { code: 0, stdout: "bad-json" },
		{ code: 0, stdout: "null" }, { code: 0, stdout: '{"level":"allowlist"}' },
		{ code: 0, stdout: '{"level":"warn"}' }]) {
		api.exec = async () => result;
		check((await handler(event("git status"), ctx)).block === true, "pi blocks bridge failure/unknown output");
	}
	api.exec = async () => { throw new Error("timeout"); };
	check((await handler(event("git status"), ctx)).block === true, "pi blocks bridge timeout");
	console.log(`Plugin checks passed: ${count}; host APIs mocked, no real-client validation.`);
} finally {
	childProcess.spawnSync = realSpawn;
	syncBuiltinESMExports();
	await rm(home, { recursive: true, force: true });
}
