/** TermYes pi adapter: no confirmation dialogs; warnings and bridge errors block. */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import * as path from "node:path";
import { fileURLToPath } from "node:url";

export default function (pi: ExtensionAPI) {
	const here = path.dirname(fileURLToPath(import.meta.url));
	const guard = path.join(here, "..", "guard", "termosaic", "pi", "danger-guard-pi.py");
	pi.on("tool_call", async (event, ctx) => {
		if (!isToolCallEventType("bash", event)) return;
		const denied = (reason: string) => ({ block: true, reason: "[命令守卫] " + reason });
		const command = event.input.command;
		if (typeof command !== "string" || !command.trim()) return denied("无效的命令");
		try {
			const cwd = ctx.cwd || process.cwd();
			const result = await pi.exec("/usr/bin/python3", [guard, JSON.stringify({ command, cwd })], {
				cwd, timeout: 8000,
			});
			if (result.code !== 0 || !result.stdout) return denied("守卫不可用，已停止执行");
			const out = JSON.parse(result.stdout);
			if (out?.level === "safe") return;
			return denied(out?.reason || "危险或无法判定的命令；请改用安全方案");
		} catch {
			return denied("守卫异常或超时，已停止执行");
		}
	});
}
