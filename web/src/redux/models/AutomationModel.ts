export type DocFieldType = 'string' | 'number' | 'date' | 'boolean';

export interface DocField {
  key: string;
  label: string;
  type: DocFieldType;
  description?: string;
  required?: boolean;
}

export interface DocTypeExample {
  id: string;
  doc_type_id: string;
  s3_key: string;
  expected_fields: Record<string, any>;
  source: 'upload' | 'correction';
  active: boolean;
  createdAt: string;
  docType?: { id: string; key: string; name: string };
}

export interface DocType {
  id: string;
  key: string;
  name: string;
  description?: string | null;
  identify_hints?: string | null;
  keywords?: string[] | null;
  fields: DocField[];
  active: boolean;
  version: number;
  exampleCount?: number;
  examples?: DocTypeExample[];
}

export type Operator =
  | 'eq'
  | 'neq'
  | 'gt'
  | 'gte'
  | 'lt'
  | 'lte'
  | 'between'
  | 'contains'
  | 'in'
  | 'exists'
  | 'missing'
  | 'is_true'
  | 'is_false';

export interface Condition {
  field: string;
  op: Operator;
  value?: any;
}

export type ConditionGroup = { all: ConditionNode[] } | { any: ConditionNode[] };
export type ConditionNode = ConditionGroup | Condition;

export type FlowAction =
  | { type: 'reply_driver'; template: string }
  | { type: 'alert_staff'; title?: string; template: string; severity?: 'info' | 'warning' | 'critical' }
  | { type: 'tag'; tags: string[] }
  | { type: 'webhook'; url: string; include_image_url?: boolean };

export type FlowTrigger = 'document_analyzed' | 'attachment_received';

export interface Flow {
  id: string;
  name: string;
  description?: string | null;
  trigger: FlowTrigger;
  priority: number;
  active: boolean;
  shadow_mode: boolean;
  conditions: ConditionGroup;
  actions: FlowAction[];
  else_actions: FlowAction[];
  cooldown_minutes: number;
  stop_on_match: boolean;
  last7Days?: { matched: number; total: number };
  updatedAt?: string;
}

export interface TraceNode {
  result: boolean;
  type: 'all' | 'any' | 'condition';
  field?: string;
  op?: Operator;
  expected?: any;
  actual?: any;
  children?: TraceNode[];
}

export interface ActionResult {
  type: string;
  ok: boolean;
  planned?: boolean;
  preview?: any;
  error?: string;
}

export interface FlowRun {
  id: string;
  flow_id: string;
  message_id: string;
  driver_id?: string | null;
  doc_type_key?: string | null;
  matched: boolean;
  shadow: boolean;
  skipped_reason?: string | null;
  context_snapshot?: any;
  condition_trace?: TraceNode;
  action_results?: ActionResult[];
  error?: string | null;
  createdAt: string;
  flow?: { id: string; name: string };
}

export interface DocumentAnalysis {
  is_document: boolean;
  doc_type: string;
  confidence: number;
  image_quality: 'good' | 'poor' | 'unreadable';
  notes: string | null;
  fields: Record<string, any>;
  text_found?: string[];
  classified_by?: 'ai' | 'keywords' | 'ai+keywords';
  matched_keywords?: string[];
  model: string;
  input_tokens: number;
  output_tokens: number;
  latency_ms: number;
}

export interface MessageDocument {
  id: string;
  message_id: string;
  media_key?: string | null;
  status: 'pending' | 'done' | 'failed' | 'skipped';
  doc_type_key?: string | null;
  confidence?: number | null;
  image_quality?: 'good' | 'poor' | 'unreadable' | null;
  fields?: Record<string, any> | null;
  notes?: string | null;
  tags?: string[] | null;
  error?: string | null;
  corrected_by?: string | null;
  corrected_doc_type?: string | null;
  corrected_fields?: Record<string, any> | null;
  createdAt: string;
  message?: {
    id: string;
    url?: string;
    thumbnail?: string;
    body?: string;
    channelId: string;
    userProfileId: string;
    messageTimestampUtc: string;
    sender?: { id: string; username: string };
  };
}

export interface ContextField {
  path: string;
  label: string;
  type: DocFieldType | 'enum' | 'text';
  options?: string[];
  docType?: string;
  // Only for message templates (e.g. {{flow.reasons}}), never offered as a condition
  templateOnly?: boolean;
}

export interface BuilderMeta {
  operators: Operator[];
  actionTypes: FlowAction['type'][];
  contextFields: ContextField[];
}

export interface Pagination {
  currentPage: number;
  pageSize: number;
  total: number;
  totalPages: number;
}

export interface TestFlowResult {
  context: any;
  analysis: DocumentAnalysis | null;
  result: {
    flowId: string;
    flowName: string;
    matched: boolean;
    trace: TraceNode;
    actions: ActionResult[];
  };
}

export interface UsageBucket {
  calls: number;
  input: number;
  cacheRead: number;
  cacheWrite: number;
  output: number;
  cost: number;
  avgLatencyMs: number;
}

export interface Rate {
  model: string;
  label: string;
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
}

export interface UsageReport {
  days: number;
  timezoneNote: string;
  totals: UsageBucket & { p95LatencyMs: number; cacheHitRate: number };
  daily: ({ date: string } & UsageBucket)[];
  bySource: ({ source: string } & UsageBucket)[];
  byModel: ({ model: string } & UsageBucket)[];
  byDocType: ({ docType: string } & UsageBucket)[];
  documents: {
    read: number;
    failed: number;
    skipped: number;
    pending: number;
    corrections: number;
    avgCostPerDocument: number;
    avgCallsPerDocument: number;
  };
  spend: {
    projectedMonthly: number;
    activeDays: number;
    monthToDate: number;
    monthlyBudget: number | null;
    budgetUsedPct: number | null;
  };
  config: {
    model: string;
    modelKnown: boolean;
    rate: Rate;
    maxExamplesPerType: number;
    maxExamplesTotal: number;
    automationEnabled: boolean;
    hasApiKey: boolean;
    effort: string;
    cacheMinutes: number;
  };
  estimate: {
    activeDocTypes: number;
    activeExamples: number;
    parts: { name: string; tokens: number; cached: boolean; output?: boolean }[];
    cachedPrefix: number;
    cachingLikely: boolean;
    uncachedInput: number;
    outputTokens: number;
    byModel: { model: string; label: string; warm: number; cold: number; uncached: number }[];
  };
  rateCard: Rate[];
  demoRows: number;
}

export interface AutomationSettings {
  ai: { model: string; isDefault: boolean; updatedAt: string | null; updatedBy: string | null; envDefault: string };
  models: (Rate & { estimatedPerDocument: number })[];
  precheck: {
    enabled: boolean;
    model: string;
    docTypes: { key: string; name: string }[];
    estimatedPerCheck: number;
    live: {
      docTypes: string[];
      flows: { id: string; name: string; docTypes: string[] }[];
      anyTypeFlows: { id: string; name: string }[];
    };
  };
}

export interface AutomationSettingsUpdate {
  model?: string;
  precheckEnabled?: boolean;
}
