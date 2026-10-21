import { Flow } from "../../models/Flow";
import { isScaleAgentEnabled } from "../documentAi/settings";

// Which document types the automation actually needs read: the scale agent's (when on) plus the ones
// named in the conditions of LIVE flows (on, not shadow mode, triggered by a read document). Uploads of any other type stop
// after the quick check, and with no live flow nothing is sent to the AI at all.

export interface LiveFlowDocTypes {
  docTypes: string[];
  flows: { id: string; name: string; docTypes: string[] }[];
  // Live flows without a document-type condition; they run on documents read for the flows above
  anyTypeFlows: { id: string; name: string }[];
}

const collectDocTypes = (node: any, out: Set<string>) => {
  if (!node || typeof node !== "object") return;
  if (Array.isArray(node.all)) return node.all.forEach((n: any) => collectDocTypes(n, out));
  if (Array.isArray(node.any)) return node.any.forEach((n: any) => collectDocTypes(n, out));
  if (node.field !== "doc.type") return;
  if (node.op === "eq" && node.value) out.add(String(node.value));
  if (node.op === "in" && Array.isArray(node.value)) node.value.forEach((v: any) => v && out.add(String(v)));
};

export const getLiveFlowDocTypes = async (): Promise<LiveFlowDocTypes> => {
  const flows = await Flow.findAll({
    where: { active: true, shadow_mode: false, trigger: "document_analyzed" },
    order: [["priority", "ASC"]],
  });
  const all = new Set<string>();
  const result: LiveFlowDocTypes = { docTypes: [], flows: [], anyTypeFlows: [] };
  for (const flow of flows) {
    const types = new Set<string>();
    collectDocTypes(flow.conditions, types);
    if (types.size) {
      types.forEach((t) => all.add(t));
      result.flows.push({ id: flow.id, name: flow.name, docTypes: [...types] });
    } else {
      result.anyTypeFlows.push({ id: flow.id, name: flow.name });
    }
  }
  // The scale ticket compliance agent needs scale tickets read even without a flow
  if (await isScaleAgentEnabled()) {
    all.add("scale_ticket");
    result.flows.unshift({ id: "scale-agent", name: "Scale ticket agent", docTypes: ["scale_ticket"] });
  }
  result.docTypes = [...all];
  return result;
};
