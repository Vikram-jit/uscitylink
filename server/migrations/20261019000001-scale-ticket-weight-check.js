'use strict';

const { randomUUID } = require('crypto');

// Scale ticket weight compliance: every scale ticket gets exactly one reply.
//   over limit  -> adjust the load and get a new ticket (staff alerted); stops here, so an
//                  over-limit ticket with an unreadable weight does not also get the photo reply
//   unreadable  -> send a clearer photo (never guess "good" or "over" from a missing weight)
//   within      -> good to go
// Federal limits: steer 12,000 · drive tandem 34,000 · trailer tandem 34,000 · gross 80,000 lbs.
// Admins can change any limit or wording in Automation -> Flows.

const scale = { field: 'doc.type', op: 'eq', value: 'scale_ticket' };
const WEIGHTS = [
  ['doc.fields.steer_axle_lb', 12000],
  ['doc.fields.drive_axle_lb', 34000],
  ['doc.fields.trailer_axle_lb', 34000],
  ['doc.fields.gross_lb', 80000],
];

const weightLines = [
  '3 Axles:',
  '- Steer axle: {{doc.fields.steer_axle_lb}} lbs (limit 12,000)',
  '- Drive axle: {{doc.fields.drive_axle_lb}} lbs (limit 34,000)',
  '- Trailer axle: {{doc.fields.trailer_axle_lb}} lbs (limit 34,000)',
  'Total Gross Weight: {{doc.fields.gross_lb}} lbs (limit 80,000)',
].join('\n');

const FLOWS = [
  {
    name: 'Scale ticket — over limit',
    description: 'An axle or the gross weight is over the federal limit: tell the driver to adjust the load and re-scale.',
    priority: 10,
    stop_on_match: true,
    conditions: { all: [scale, { any: WEIGHTS.map(([field, limit]) => ({ field, op: 'gt', value: limit })) }] },
    actions: [
      {
        type: 'reply_driver',
        template: `⚠️ Scale Ticket — over the limit\n\n${weightLines}\n\nWeight Compliance Check: one or more weights are over the DOT limit. Adjust the load and obtain a new scale ticket before proceeding.`,
      },
      {
        type: 'alert_staff',
        severity: 'critical',
        title: 'Overweight scale ticket — truck {{driver.truck}}',
        template:
          '{{driver.name}}: steer {{doc.fields.steer_axle_lb}}, drive {{doc.fields.drive_axle_lb}}, trailer {{doc.fields.trailer_axle_lb}}, gross {{doc.fields.gross_lb}} lbs.',
      },
      { type: 'tag', tags: ['overweight'] },
    ],
  },
  {
    name: 'Scale ticket — weights unreadable',
    description: 'One of the four weights could not be read: ask for a clearer photo instead of guessing.',
    priority: 11,
    stop_on_match: false,
    conditions: { all: [scale, { any: WEIGHTS.map(([field]) => ({ field, op: 'missing' })) }] },
    actions: [
      {
        type: 'reply_driver',
        template:
          '📷 We could not read all the weights on your scale ticket. Please send a clear, straight photo of the whole ticket so we can check the axle weights.',
      },
    ],
  },
  {
    name: 'Scale ticket — within limits',
    description: 'All axle and gross weights are within the federal limits: the truck is good to go.',
    priority: 12,
    stop_on_match: false,
    conditions: { all: [scale, ...WEIGHTS.map(([field, limit]) => ({ field, op: 'lte', value: limit }))] },
    actions: [
      {
        type: 'reply_driver',
        template: `✅ Scale Ticket\n\n${weightLines}\n\nWeight Compliance Check: all axle and gross weights are within the DOT limits. You are good to go.`,
      },
    ],
  },
];

// The original seeded scale flows would send a second, different reply for the same ticket
const REPLACED = ['Scale ticket — overweight', 'Scale ticket — legal'];

module.exports = {
  async up(queryInterface) {
    const [existing] = await queryInterface.sequelize.query('SELECT name FROM flows');
    const names = new Set(existing.map((r) => r.name));
    const now = new Date();
    const rows = FLOWS.filter((fl) => !names.has(fl.name)).map((fl) => ({
      id: randomUUID(),
      name: fl.name,
      description: fl.description,
      trigger: 'document_analyzed',
      priority: fl.priority,
      // Live: only document types used by live flows are read (see Automation -> Settings)
      active: true,
      shadow_mode: false,
      conditions: JSON.stringify(fl.conditions),
      actions: JSON.stringify(fl.actions),
      else_actions: JSON.stringify([]),
      cooldown_minutes: 0,
      stop_on_match: fl.stop_on_match,
      createdAt: now,
      updatedAt: now,
    }));
    if (rows.length) await queryInterface.bulkInsert('flows', rows);
    await queryInterface.bulkUpdate('flows', { active: false, updatedAt: now }, { name: REPLACED });
  },

  async down(queryInterface) {
    await queryInterface.bulkDelete('flows', { name: FLOWS.map((fl) => fl.name) });
  },
};
