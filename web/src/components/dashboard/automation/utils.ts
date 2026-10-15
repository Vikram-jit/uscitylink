import type { ActionResult, Condition, ConditionGroup, ConditionNode, Operator } from '@/redux/models/AutomationModel';

export const s3Url = (key?: string | null) => (key ? `https://ciity-sms.s3.us-west-1.amazonaws.com/${key}` : '');

export const OPERATOR_LABELS: Record<Operator, string> = {
  eq: 'equals',
  neq: 'does not equal',
  gt: 'is greater than',
  gte: 'is at least',
  lt: 'is less than',
  lte: 'is at most',
  between: 'is between',
  contains: 'contains',
  in: 'is one of',
  exists: 'is present',
  missing: 'is missing',
  is_true: 'is yes',
  is_false: 'is no',
};

export const VALUELESS_OPERATORS: Operator[] = ['exists', 'missing', 'is_true', 'is_false'];

export const ACTION_LABELS: Record<string, string> = {
  reply_driver: 'Reply to driver',
  alert_staff: 'Alert dispatch',
  tag: 'Tag document',
  webhook: 'Call webhook',
};

export const isGroup = (node: ConditionNode): node is ConditionGroup => 'all' in node || 'any' in node;
export const isCondition = (node: ConditionNode): node is Condition => !isGroup(node);
export const groupMode = (group: ConditionGroup): 'all' | 'any' => ('all' in group ? 'all' : 'any');
export const groupChildren = (group: ConditionGroup): ConditionNode[] =>
  'all' in group ? group.all : group.any;

export const formatValue = (value: any): string => {
  if (value === undefined || value === null || value === '') return '—';
  if (Array.isArray(value)) return value.join(', ');
  if (typeof value === 'boolean') return value ? 'yes' : 'no';
  if (typeof value === 'number') return value.toLocaleString('en-US');
  return String(value);
};

export const describeAction = (result: ActionResult): string => {
  const p = result.preview || {};
  switch (result.type) {
    case 'reply_driver':
      return p.body || '';
    case 'alert_staff':
      return [p.title, p.body].filter(Boolean).join(' — ');
    case 'tag':
      return (p.tags || []).join(', ');
    case 'webhook':
      return p.url || '';
    default:
      return result.error || '';
  }
};

export const humanizeKey = (key?: string | null) =>
  (key || 'unknown').replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase());
