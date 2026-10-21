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
  // ELSE IF branches, checked in order when IF does not match
  else_if?: FlowBranch[] | null;
  cooldown_minutes: number;
  stop_on_match: boolean;
  last7Days?: { matched: number; total: number };
  updatedAt?: string;
}

export interface FlowBranch {
  name?: string;
  conditions: ConditionGroup;
  actions: FlowAction[];
}

export interface BranchInfo {
  kind: 'if' | 'else_if' | 'else' | 'none';
  index?: number;
  name?: string;
}

export interface TraceNode {
  result: boolean;
  type: 'all' | 'any' | 'condition';
  field?: string;
  op?: Operator;
  expected?: any;
  actual?: any;
  children?: TraceNode[];
  // Top-level trace of a flow run: which branch ran, and the ELSE IF conditions that decided it
  branch?: BranchInfo;
  branch_trace?: TraceNode | null;
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
  // Present for scale tickets: the compliance agent's check
  scale_check?: ScaleCheck | null;
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
    branch?: BranchInfo;
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
  scaleAgent: { enabled: boolean; releaseRole: 'staff' | 'admin'; webhookUrl: string | null };
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
  scaleAgentEnabled?: boolean;
  scaleReleaseRole?: 'staff' | 'admin';
  scaleWebhookUrl?: string;
}

// ---------- Scale ticket compliance agent ----------

export type ScaleStatus =
  | 'PASS_PRELIMINARY'
  | 'OVER_GROSS'
  | 'ADJUST_AND_REWEIGH'
  | 'OCR_UNCERTAIN'
  | 'ROUTE_REVIEW_REQUIRED'
  | 'BRIDGE_REVIEW';
export type ScaleApproval = 'pending' | 'approved' | 'rejected' | 'not_required' | 'superseded';
export type ScaleGroup = 'steer' | 'drive' | 'trailer' | 'gross';

export interface ScaleAdjustment {
  action: 'tandems_forward' | 'tandems_backward' | 'fifth_wheel_forward' | 'fifth_wheel_back' | 'rework_cargo';
  from?: ScaleGroup;
  to?: ScaleGroup;
  needed_lb?: number;
  available_lb?: number;
  holes?: number | null;
  kpra_after_ft?: number | null;
  reason?: 'weight' | 'kpra';
}

export interface ScaleCheck {
  id: string;
  message_id: string;
  driver_id?: string | null;
  driver_name?: string | null;
  channel_id?: string | null;
  truck?: string | null;
  ticket_number?: string | null;
  measured_weights?: Partial<Record<ScaleGroup, number | null>> | null;
  confidence?: number | null;
  image_quality?: string | null;
  rule_set_version?: string | null;
  model?: string | null;
  status: ScaleStatus;
  flags?: string[] | null;
  group_overages_lb?: Partial<Record<ScaleGroup, number>> | null;
  headroom_lb?: Partial<Record<ScaleGroup, number>> | null;
  feasible_adjustments?: ScaleAdjustment[] | null;
  assumptions?: string[] | null;
  required_actions?: string[] | null;
  driver_message?: string | null;
  previous_check_id?: string | null;
  reweigh_check_id?: string | null;
  approval_status: ScaleApproval;
  approved_by?: string | null;
  approved_by_name?: string | null;
  approved_at?: string | null;
  approval_note?: string | null;
  trip_id?: string | null;
  tractor_unit?: string | null;
  trailer_unit?: string | null;
  controlling_rules?: {
    route_known: boolean;
    segments: { state: string; road_class: string; rules: string[]; missing: boolean; unverified: string[]; permit?: string | null; expired_permit?: string | null }[];
    limits: { single_axle_lb: number; tandem_lb: number; gross_lb: number; steer_target_lb?: number | null; kpra_max_ft?: number | null };
    sources: Record<string, string>;
    rule_labels: string[];
    missing: string[];
    unverified: string[];
    axle_positions_ft?: number[] | null;
    equipment_missing?: string[];
  } | null;
  bridge_results?: { axles: string; count: number; length_ft: number; weight_lb: number; limit_lb: number; over_lb: number; rule: string }[] | null;
  kpra?: { required: boolean; max_ft: number | null; kpra_ft: number | null; over_ft: number | null; verified: boolean } | null;
  adjustment_made?: { action: string; holes?: number | null; parked_confirmed: boolean; by?: string; at?: string } | null;
  prediction?: { action: string; holes: number | null; expected_shift_lb: number | null; actual_shift_lb: number | null; direction_ok: boolean | null; mismatch: boolean; learned_lb_per_hole: number | null; note: string } | null;
  createdAt: string;
}

export interface WeightRuleSet {
  id: string;
  jurisdiction: string;
  road_class: string;
  version: number;
  name: string;
  single_axle_lb: number;
  tandem_lb: number;
  gross_lb: number;
  steer_target_lb?: number | null;
  sum_tolerance_lb: number;
  min_confidence: number;
  citation?: string | null;
  source_url?: string | null;
  effective_date?: string | null;
  notes?: string | null;
  active: boolean;
  kpra_max_ft?: number | null;
  bridge_formula: boolean;
  review_months: number;
  reviewed_at?: string | null;
  reviewed_by_name?: string | null;
  verified?: boolean;
  review_due?: string | null;
  createdAt: string;
}

export interface EquipmentProfile {
  id: string;
  kind: 'tractor' | 'trailer';
  unit_number: string;
  axle_count?: number | null;
  steer_to_drive_center_ft?: number | null;
  drive_spread_ft?: number | null;
  kingpin_to_drive_center_ft?: number | null;
  fifth_wheel_range_in?: number | null;
  kpra_ft?: number | null;
  trailer_spread_ft?: number | null;
  length_ft?: number | null;
  hole_spacing_in?: number | null;
  holes_forward_available?: number | null;
  holes_back_available?: number | null;
  steer_rating_lb?: number | null;
  drive_rating_lb?: number | null;
  trailer_rating_lb?: number | null;
  gvwr_lb?: number | null;
  lb_per_hole?: number | null;
  lb_per_hole_samples?: number;
  notes?: string | null;
  updatedAt?: string;
}

export type RoadClass = 'interstate' | 'state_highway' | 'local';

export interface DriverTrip {
  id?: string;
  driver_id?: string;
  driver_name?: string | null;
  truck?: string | null;
  trailer?: string | null;
  origin?: string | null;
  destination?: string | null;
  cargo?: string | null;
  notes?: string | null;
  segments: { state: string; road_class: RoadClass; note?: string }[];
  permits: { state: string; number: string; expires_at: string; gross_lb?: number | null; tandem_lb?: number | null; single_axle_lb?: number | null }[];
  updatedAt?: string;
}
