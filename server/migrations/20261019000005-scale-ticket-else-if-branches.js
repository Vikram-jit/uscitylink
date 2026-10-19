'use strict';

// Scale ticket weight check as IF / ELSE IF / ELSE, so the driver gets the right message for the
// problem instead of one generic reply:
//   IF all weights within limits      -> good to go
//   ELSE IF a weight is unreadable    -> send a clear photo
//   ELSE IF gross over                -> load too heavy, weight has to come off
//   ELSE IF steer / drive / trailer   -> how to shift the weight, then re-scale
//   ELSE                              -> list what failed
// {{flow.failed}} lists every failed check, so a ticket with two axles over shows both.
// The IF limits already set on the flow are reused for the ELSE IF checks.

const NAME = 'Scale ticket — weight check';
const DEFAULTS = {
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

const limitsFrom = (conditions) => {
  const limits = { ...DEFAULTS };
  (conditions?.all || []).forEach((c) => {
    if (c && c.field in limits && (c.op === 'lte' || c.op === 'lt') && Number.isFinite(Number(c.value))) {
      limits[c.field] = Number(c.value);
    }
  });
  return limits;
};

const alert = {
  type: 'alert_staff',
  severity: 'critical',
  title: 'Scale ticket over the limit — truck {{driver.truck}}',
  template: '{{driver.name}}:\n{{flow.failed}}',
};

const overBranch = (name, field, limit, advice) => ({
  name,
  conditions: { all: [{ field, op: 'gt', value: limit }] },
  actions: [
    {
      type: 'reply_driver',
      template: `⚠️ Scale Ticket — ${name.toLowerCase()}\n\n{{flow.failed}}\n\n${advice}`,
    },
    alert,
    { type: 'tag', tags: ['overweight'] },
  ],
});

const branchesFor = (limits) => [
  {
    name: 'Weight unreadable',
    conditions: { any: Object.keys(DEFAULTS).map((field) => ({ field, op: 'missing' })) },
    actions: [
      {
        type: 'reply_driver',
        template:
          '📷 We could not read all the weights on your scale ticket:\n{{flow.reasons}}\n\nPlease send a clear, straight photo of the whole ticket so we can check the axle weights.',
      },
      { type: 'tag', tags: ['scale-unreadable'] },
    ],
  },
  overBranch(
    'Gross weight over the limit',
    'doc.fields.gross_lb',
    limits['doc.fields.gross_lb'],
    'The load is too heavy; sliding will not fix it. Do not roll. Call dispatch so weight can be taken off, then get a new scale ticket.',
  ),
  overBranch(
    'Steer axle over the limit',
    'doc.fields.steer_axle_lb',
    limits['doc.fields.steer_axle_lb'],
    'Slide the fifth wheel back to move weight off the steer axle, then obtain a new scale ticket before proceeding.',
  ),
  overBranch(
    'Drive axle over the limit',
    'doc.fields.drive_axle_lb',
    limits['doc.fields.drive_axle_lb'],
    'Slide the fifth wheel forward or the trailer tandems forward to move weight off the drive axle, then obtain a new scale ticket before proceeding.',
  ),
  overBranch(
    'Trailer axle over the limit',
    'doc.fields.trailer_axle_lb',
    limits['doc.fields.trailer_axle_lb'],
    'Slide the trailer tandems back to move weight off the trailer axle, then obtain a new scale ticket before proceeding.',
  ),
];

const ELSE = [
  {
    type: 'reply_driver',
    template: '⚠️ Scale Ticket — not good to go\n\n{{flow.failed}}\n\nPlease call dispatch before proceeding.',
  },
  { ...alert, title: 'Scale ticket problem — truck {{driver.truck}}' },
];

module.exports = {
  async up(queryInterface) {
    const [rows] = await queryInterface.sequelize.query('SELECT id, conditions FROM flows WHERE name = :name', {
      replacements: { name: NAME },
    });
    for (const flow of rows) {
      const limits = limitsFrom(parse(flow.conditions));
      await queryInterface.sequelize.query(
        'UPDATE flows SET else_if = :elseIf, else_actions = :elseActions, updatedAt = NOW() WHERE id = :id',
        { replacements: { id: flow.id, elseIf: JSON.stringify(branchesFor(limits)), elseActions: JSON.stringify(ELSE) } },
      );
    }
  },

  async down(queryInterface) {
    await queryInterface.sequelize.query('UPDATE flows SET else_if = NULL WHERE name = :name', { replacements: { name: NAME } });
  },
};
