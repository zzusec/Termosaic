/** TermYes OpenCode adapter: a missing/broken bridge is a tool error, never permission. */
import { spawnSync } from "node:child_process";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

export const BypassYesGuard = async ({ directory, worktree }) => {
	const here = path.dirname(fileURLToPath(import.meta.url));
	const guard = path.join(here, "..", "hooks", "termosaic", "opencode", "danger-guard-pi.py");
	return {
		"tool.execute.before": async (input, output) => {
			if (input.tool !== "bash") return;
			const command = output?.args?.command;
			if (typeof command !== "string" || !command.trim()) throw new Error("[命令守卫] 无效的命令");
			let out;
			try {
				const result = spawnSync("/usr/bin/python3", [guard, JSON.stringify({
					command, cwd: directory || worktree || process.cwd(),
				})], { encoding: "utf8", timeout: 8000, maxBuffer: 1024 * 1024 });
				if (result.error || result.status !== 0 || !result.stdout) throw new Error();
				out = JSON.parse(result.stdout);
			} catch {
				throw new Error("[命令守卫] 守卫异常或超时，已停止执行");
			}
			if (out?.level !== "safe") throw new Error("[命令守卫] " + (out?.reason || "无法判定命令") + "；请改用安全方案");
		},
	};
};
