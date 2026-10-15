'use strict';

const { randomUUID } = require('crypto');

const f = (key, label, type, description = '') => ({ key, label, type, description, required: false });

const DOC_TYPES = [
  {
    key: 'scale_ticket',
    name: 'Scale ticket',
    description: 'Certified truck scale weight ticket (CAT Scale or similar) showing axle weights.',
    identify_hints:
      'Usually yellow paper with a scale company logo (CAT Scale), "Weigh number", "Ticket number", and separate Steer axle, Drive axle, Trailer axle and Gross weight lines. Often photographed sideways.',
    fields: [
      f('steer_axle_lb', 'Steer axle (lb)', 'number'),
      f('drive_axle_lb', 'Drive axle (lb)', 'number'),
      f('trailer_axle_lb', 'Trailer axle (lb)', 'number'),
      f('gross_lb', 'Gross weight (lb)', 'number'),
      f('tractor_number', 'Tractor #', 'string'),
      f('trailer_number', 'Trailer #', 'string'),
      f('ticket_number', 'Ticket number', 'string'),
      f('weigh_date', 'Weigh date', 'date'),
      f('location', 'Scale location', 'string', 'Truck stop name, city and state'),
    ],
  },
  {
    key: 'bol_pickup',
    name: 'Bill of lading (pickup)',
    description: 'Bill of lading given to the driver at the shipper when the load is picked up. No receiver signature or delivery stamp yet.',
    identify_hints:
      'Titled "Bill of Lading" / "Straight Bill of Lading". Lists shipper, consignee, items, pieces and weights. Has no consignee receipt stamp or receiver signature.',
    fields: [
      f('bol_number', 'BOL #', 'string', 'Bill of lading number or shipper number'),
      f('po_number', 'PO #', 'string'),
      f('shipper', 'Shipper', 'string'),
      f('consignee', 'Consignee', 'string'),
      f('destination', 'Destination', 'string', 'City and state'),
      f('seal_number', 'Seal #', 'string'),
      f('temp_setpoint', 'Temperature setpoint', 'string', 'e.g. "-10F" or "42-44F"'),
      f('total_pieces', 'Total pieces/cases', 'number'),
      f('total_weight_lb', 'Total weight (lb)', 'number'),
      f('pickup_date', 'Pickup date', 'date'),
    ],
  },
  {
    key: 'pod_signed',
    name: 'Signed BOL / proof of delivery',
    description: 'Bill of lading after delivery, signed or stamped by the receiver.',
    identify_hints:
      'Same as a bill of lading but with a receiver stamp, "Received by" signature, received quantities, or over/short/damage notes from the consignee.',
    fields: [
      f('bol_number', 'BOL #', 'string'),
      f('consignee', 'Consignee', 'string'),
      f('received_qty', 'Received quantity', 'number'),
      f('receiver_signature_present', 'Receiver signed', 'boolean'),
      f('over', 'Over', 'string', 'Overage noted by receiver, null if none'),
      f('short', 'Short', 'string', 'Shortage noted by receiver, null if none'),
      f('damage', 'Damage', 'string', 'Damage noted by receiver, null if none'),
      f('seal_number', 'Seal #', 'string'),
      f('delivered_date', 'Delivered date', 'date'),
    ],
  },
  {
    key: 'lumper_receipt',
    name: 'Lumper receipt',
    description: 'Receipt for unloading (lumper) service paid at the receiver.',
    identify_hints: 'Mentions lumper, unloading, or a lumper service company; shows an amount paid.',
    fields: [
      f('vendor', 'Vendor', 'string'),
      f('amount', 'Amount ($)', 'number'),
      f('receipt_date', 'Date', 'date'),
      f('reference', 'Reference / PO #', 'string'),
      f('payment_method', 'Payment method', 'string', 'e.g. Comchek, EFS, cash'),
    ],
  },
  {
    key: 'fuel_receipt',
    name: 'Fuel receipt',
    description: 'Fuel purchase receipt from a truck stop.',
    identify_hints: 'Shows gallons, price per gallon, pump number, diesel/DEF.',
    fields: [
      f('vendor', 'Truck stop', 'string'),
      f('amount', 'Total ($)', 'number'),
      f('gallons', 'Gallons', 'number'),
      f('receipt_date', 'Date', 'date'),
      f('location', 'Location', 'string'),
    ],
  },
];

const isType = (key) => ({ field: 'doc.type', op: 'eq', value: key });

const FLOWS = [
  {
    name: 'Bad photo — ask for retake',
    priority: 10,
    stop_on_match: true,
    cooldown_minutes: 10,
    conditions: { any: [{ field: 'doc.quality', op: 'in', value: ['poor', 'unreadable'] }] },
    actions: [
      {
        type: 'reply_driver',
        template:
          'The photo is hard to read. Please retake it in good light with the whole page in the frame. Thanks!',
      },
    ],
  },
  {
    name: 'Scale ticket — overweight',
    priority: 20,
    stop_on_match: true,
    conditions: {
      all: [
        isType('scale_ticket'),
        {
          any: [
            { field: 'doc.fields.gross_lb', op: 'gt', value: 80000 },
            { field: 'doc.fields.steer_axle_lb', op: 'gt', value: 12000 },
            { field: 'doc.fields.drive_axle_lb', op: 'gt', value: 34000 },
            { field: 'doc.fields.trailer_axle_lb', op: 'gt', value: 34000 },
          ],
        },
      ],
    },
    actions: [
      {
        type: 'reply_driver',
        template:
          '⚠️ Overweight on the scale ticket — gross {{doc.fields.gross_lb}} lb (steer {{doc.fields.steer_axle_lb}}, drive {{doc.fields.drive_axle_lb}}, trailer {{doc.fields.trailer_axle_lb}}). Do not roll; call dispatch now.',
      },
      {
        type: 'alert_staff',
        severity: 'critical',
        title: 'Overweight: truck {{driver.truck}}',
        template:
          '{{driver.name}} — gross {{doc.fields.gross_lb}} lb, drive {{doc.fields.drive_axle_lb}}, trailer {{doc.fields.trailer_axle_lb}}.',
      },
      { type: 'tag', tags: ['overweight'] },
    ],
  },
  {
    name: 'Scale ticket — legal',
    priority: 30,
    conditions: { all: [isType('scale_ticket'), { field: 'doc.fields.gross_lb', op: 'exists' }] },
    actions: [
      {
        type: 'reply_driver',
        template: '✅ Scale ticket received — gross {{doc.fields.gross_lb}} lb. Thanks!',
      },
    ],
  },
  {
    name: 'Pickup BOL — missing seal #',
    priority: 40,
    cooldown_minutes: 30,
    conditions: { all: [isType('bol_pickup'), { field: 'doc.fields.seal_number', op: 'missing' }] },
    actions: [
      {
        type: 'reply_driver',
        template:
          'BOL received, but I can\'t see a seal number on it. Please send a clear photo of the seal on the trailer door.',
      },
    ],
    else_actions: [],
  },
  {
    name: 'POD — unsigned or OS&D',
    priority: 50,
    conditions: {
      all: [
        isType('pod_signed'),
        {
          any: [
            { field: 'doc.fields.receiver_signature_present', op: 'is_false' },
            { field: 'doc.fields.over', op: 'exists' },
            { field: 'doc.fields.short', op: 'exists' },
            { field: 'doc.fields.damage', op: 'exists' },
          ],
        },
      ],
    },
    actions: [
      {
        type: 'reply_driver',
        template:
          'Before you leave the receiver: make sure the BOL is signed and any over/short/damage is written on it. Dispatch has been notified.',
      },
      {
        type: 'alert_staff',
        severity: 'warning',
        title: 'POD issue: truck {{driver.truck}}',
        template:
          '{{driver.name}} — BOL {{doc.fields.bol_number}}: signed={{doc.fields.receiver_signature_present}}, over={{doc.fields.over}}, short={{doc.fields.short}}, damage={{doc.fields.damage}}.',
      },
      { type: 'tag', tags: ['osd'] },
    ],
  },
  {
    name: 'Low confidence — flag for review',
    priority: 90,
    conditions: { all: [{ field: 'doc.confidence', op: 'lt', value: 0.6 }] },
    actions: [{ type: 'tag', tags: ['needs_review'] }],
  },
];

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface) {
    const now = new Date();
    const [existingTypes] = await queryInterface.sequelize.query('SELECT `key` FROM doc_types');
    const existingKeys = new Set(existingTypes.map((t) => t.key));
    const typeRows = DOC_TYPES.filter((d) => !existingKeys.has(d.key)).map((d) => ({
      id: randomUUID(),
      ...d,
      fields: JSON.stringify(d.fields),
      active: true,
      version: 1,
      createdAt: now,
      updatedAt: now,
    }));
    if (typeRows.length) await queryInterface.bulkInsert('doc_types', typeRows);

    const [existingFlows] = await queryInterface.sequelize.query('SELECT name FROM flows');
    const existingNames = new Set(existingFlows.map((fl) => fl.name));
    const flowRows = FLOWS.filter((fl) => !existingNames.has(fl.name)).map((fl) => ({
      id: randomUUID(),
      name: fl.name,
      description: null,
      trigger: 'document_analyzed',
      priority: fl.priority,
      // Seeded off and in shadow mode: review the run log before letting them message drivers
      active: false,
      shadow_mode: true,
      conditions: JSON.stringify(fl.conditions),
      actions: JSON.stringify(fl.actions),
      else_actions: JSON.stringify(fl.else_actions || []),
      cooldown_minutes: fl.cooldown_minutes || 0,
      stop_on_match: !!fl.stop_on_match,
      createdAt: now,
      updatedAt: now,
    }));
    if (flowRows.length) await queryInterface.bulkInsert('flows', flowRows);
  },

  async down(queryInterface) {
    await queryInterface.bulkDelete('flows', { name: FLOWS.map((fl) => fl.name) });
    await queryInterface.bulkDelete('doc_types', { key: DOC_TYPES.map((d) => d.key) });
  },
};
