import crypto from "crypto";
import { getSocketInstance } from "../../../sockets/socket";
import { sendSystemMessageToDriver } from "../../../sockets/messageHandler";
import { MessageDocument } from "../../../models/MessageDocument";
import { FlowContext } from "../context";
import { renderTemplate } from "../template";
import { getBotProfileId } from "../botProfile";

export type FlowAction =
  | { type: "reply_driver"; template: string }
  | { type: "alert_staff"; title?: string; template: string; severity?: "info" | "warning" | "critical" }
  | { type: "tag"; tags: string[] }
  | { type: "webhook"; url: string; include_image_url?: boolean };

export const ACTION_TYPES = ["reply_driver", "alert_staff", "tag", "webhook"] as const;

export interface ActionRunInfo {
  flowId: string;
  flowName: string;
  flowRunId: string | null;
}

export interface ActionResult {
  type: string;
  ok: boolean;
  planned?: boolean;
  preview?: any;
  error?: string;
}

// What the action would do, without doing it (shadow mode and the flow tester)
export const previewAction = (action: FlowAction, ctx: FlowContext): any => {
  switch (action.type) {
    case "reply_driver":
      return { body: renderTemplate(action.template, ctx) };
    case "alert_staff":
      return {
        title: renderTemplate(action.title || "", ctx),
        body: renderTemplate(action.template, ctx),
        severity: action.severity || "warning",
      };
    case "tag":
      return { tags: action.tags };
    case "webhook":
      return { url: action.url };
    default:
      return null;
  }
};

export const sendWebhook = async (url: string, payload: any) => {
  const body = JSON.stringify(payload);
  const signature = crypto
    .createHmac("sha256", process.env.AUTOMATION_WEBHOOK_SECRET || "")
    .update(body)
    .digest("hex");

  let lastError: any;
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const res = await fetch(url, {
        method: "POST",
        headers: { "Content-Type": "application/json", "X-USCityLink-Signature": signature },
        body,
        signal: AbortSignal.timeout(5000),
      });
      if (res.ok) return res.status;
      lastError = new Error(`Webhook responded ${res.status}`);
      if (res.status < 500) break; // the receiver rejected it; retrying won't help
    } catch (err) {
      lastError = err;
    }
    await new Promise((r) => setTimeout(r, 500 * 2 ** attempt));
  }
  throw lastError;
};

export const runAction = async (
  action: FlowAction,
  ctx: FlowContext,
  info: ActionRunInfo,
): Promise<ActionResult> => {
  const preview = previewAction(action, ctx);
  try {
    switch (action.type) {
      case "reply_driver": {
        const botId = await getBotProfileId();
        await sendSystemMessageToDriver(
          getSocketInstance(),
          botId,
          ctx.driver.id,
          ctx.message.channel_id,
          preview.body,
          { replyToId: ctx.message.id, flowRunId: info.flowRunId },
        );
        break;
      }
      case "alert_staff": {
        const io = getSocketInstance();
        const alert = {
          ...preview,
          flowId: info.flowId,
          flowName: info.flowName,
          flowRunId: info.flowRunId,
          messageId: ctx.message.id,
          channelId: ctx.message.channel_id,
          driverId: ctx.driver.id,
          driverName: ctx.driver.name,
          truck: ctx.driver.truck,
          docType: ctx.doc.type,
          createdAt: new Date().toISOString(),
        };
        Object.keys(global.staffActiveChannel || {}).forEach((staffId) => {
          const socket = global.userSockets[staffId];
          if (socket) io.to(socket.id).emit("automation_alert", alert);
        });
        break;
      }
      case "tag": {
        const doc = await MessageDocument.findOne({ where: { message_id: ctx.message.id } });
        if (doc) {
          const tags = Array.from(new Set([...(doc.tags || []), ...(action.tags || [])]));
          await doc.update({ tags });
        }
        break;
      }
      case "webhook": {
        await sendWebhook(action.url, {
          event: "flow.matched",
          flow: { id: info.flowId, name: info.flowName },
          flow_run_id: info.flowRunId,
          document: ctx.doc,
          driver: ctx.driver,
          message: {
            ...ctx.message,
            ...(action.include_image_url && ctx.message.url
              ? { image_url: `https://${process.env.BUCKET_NAME || "ciity-sms"}.s3.us-west-1.amazonaws.com/${ctx.message.url}` }
              : {}),
          },
          sent_at: new Date().toISOString(),
        });
        break;
      }
      default:
        return { type: (action as any).type, ok: false, error: "Unknown action type" };
    }
    return { type: action.type, ok: true, preview };
  } catch (err: any) {
    return { type: action.type, ok: false, preview, error: err?.message || String(err) };
  }
};

export const validateAction = (action: any): string | null => {
  if (!action || !ACTION_TYPES.includes(action.type)) return `Unknown action type "${action?.type}"`;
  if ((action.type === "reply_driver" || action.type === "alert_staff") && !action.template?.trim()) {
    return `${action.type} needs a message template`;
  }
  if (action.type === "tag" && (!Array.isArray(action.tags) || !action.tags.length)) {
    return "tag needs at least one tag";
  }
  if (action.type === "webhook") {
    try {
      const u = new URL(action.url);
      if (u.protocol !== "https:" && u.protocol !== "http:") return "Webhook URL must be http(s)";
    } catch {
      return "Webhook URL is invalid";
    }
  }
  return null;
};
