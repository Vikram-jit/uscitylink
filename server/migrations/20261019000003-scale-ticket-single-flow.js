'use strict';

const { randomUUID } = require('crypto');

// One flow instead of three for the scale ticket weight check:
//   if every weight is within its limit  -> "good to go" ({{flow.checks}} lists each weight and limit)
//   otherwise                            -> {{flow.reasons}} lists only what failed: a weight over its
//                                           limit, or a weight that could not be read
// The "otherwise" branch never runs for other document types (see flowEngine/runFlows).
// Limits already edited on "Scale ticket — over limit" are carried over.

const NAME = 'Scale ticket — weight check';
const OLD = ['Scale ticket — over limit', 'Scale ticket — weights unreadable', 'Scale ticket — within limits'];
const DEFAULT_LIMITS = {
  'doc.fields.steer_axle_lb': 12000,
  'doc.fields.drive_axle_lb': 34000,
  'doc.fields.trailer_axle_lb': 34000,
  'doc.fields.gross_lb': 80000,
};

const parse = (v) => {
  if (v && typeof v === 'object') return v;
  try {
    return JSON.parse(v || 'null');
  } catch {
    return null;
  }
};

// Read the limits from the old over-limit flow ("steer > 12,300" means a 12,300 limit)
const limitsFrom = (conditions) => {
  const limits = { ...DEFAULT_LIMITS };
  const walk = (node) => {
    if (!node || typeof node !== 'object') return;
    (node.all || node.any || []).forEach(walk);
    if (node.field in limits && (node.op === 'gt' || node.op === 'gte') && Number.isFinite(Number(node.value))) {
      limits[node.field] = Number(node.value);
    }
  };
  walk(conditions);
  return limits;
};

module.exports = {
  async up(queryInterface) {
    const [flows] = await queryInterface.sequelize.query('SELECT id, name, conditions FROM flows WHERE name IN (:names)', {
      replacements: { names: [NAME, ...OLD] },
    });
    const overLimit = flows.find((f) => f.name === OLD[0]);
    const limits = limitsFrom(parse(overLimit && overLimit.conditions));
    const now = new Date();

    if (!flows.some((f) => f.name === NAME)) {
      await queryInterface.bulkInsert('flows', [
        {
          id: randomUUID(),
          name: NAME,
          description:
            'Checks every scale ticket against the axle and gross weight limits. Good to go if all are within; otherwise tells the driver exactly which weight is over (or unreadable).',
          trigger: 'document_analyzed',
          priority: 10,
          active: true,
          shadow_mode: false,
          conditions: JSON.stringify({
            all: [
              { field: 'doc.type', op: 'eq', value: 'scale_ticket' },
              ...Object.entries(limits).map(([field, value]) => ({ field, op: 'lte', value })),
            ],
          }),
          actions: JSON.stringify([
            {
              type: 'reply_driver',
              template:
                '✅ Scale Ticket\n\n{{flow.checks}}\n\nWeight Compliance Check: all axle and gross weights are within the DOT limits. You are good to go.',
            },
          ]),
          else_actions: JSON.stringify([
            {
              type: 'reply_driver',
              template:
                '⚠️ Scale Ticket — not good to go\n\n{{flow.reasons}}\n\nWeight Compliance Check: if a weight is over the limit, adjust the load and obtain a new scale ticket before proceeding. If a weight could not be read, send a clear photo of the whole ticket.',
            },
            {
              type: 'alert_staff',
              severity: 'critical',
              title: 'Scale ticket problem — truck {{driver.truck}}',
              template: '{{driver.name}}:\n{{flow.reasons}}',
            },
            { type: 'tag', tags: ['scale-check-failed'] },
          ]),
          cooldown_minutes: 0,
          stop_on_match: false,
          createdAt: now,
          updatedAt: now,
        },
      ]);
    }

    // Remove the three old flows; keep (switched off) any that already have run history
    for (const flow of flows.filter((f) => OLD.includes(f.name))) {
      const [[{ runs }]] = await queryInterface.sequelize.query('SELECT COUNT(*) AS runs FROM flow_runs WHERE flow_id = :id', {
        replacements: { id: flow.id },
      });
      if (Number(runs) > 0) {
        await queryInterface.bulkUpdate('flows', { active: false, updatedAt: now }, { id: flow.id });
      } else {
        await queryInterface.bulkDelete('flows', { id: flow.id });
      }
    }
  },

  async down(queryInterface) {
    await queryInterface.bulkDelete('flows', { name: NAME });
    await queryInterface.bulkUpdate('flows', { active: true }, { name: OLD });
  },
};
