'use strict';

// Scale ticket replies list only what is wrong ("Trailer axle: 33,980 lbs (280 lbs over the 33,700
// limit)") instead of every weight, using {{flow.reasons}} / {{flow.checks}}. Those are generated from
// each flow's own conditions, so a limit changed in the flow builder shows up in the message too.
// Only the message text is replaced; conditions (limits) and any other actions are kept.

const TEMPLATES = {
  'Scale ticket — over limit': {
    reply_driver: {
      template:
        '⚠️ Scale Ticket — over the limit\n\n{{flow.reasons}}\n\nWeight Compliance Check: adjust the load and obtain a new scale ticket before proceeding.',
    },
    alert_staff: {
      title: 'Overweight scale ticket — truck {{driver.truck}}',
      template: '{{driver.name}} — over the limit:\n{{flow.reasons}}',
    },
  },
  'Scale ticket — weights unreadable': {
    reply_driver: {
      template:
        '📷 We could not read all the weights on your scale ticket:\n{{flow.reasons}}\n\nPlease send a clear, straight photo of the whole ticket so we can check the axle weights.',
    },
  },
  'Scale ticket — within limits': {
    reply_driver: {
      template:
        '✅ Scale Ticket\n\n{{flow.checks}}\n\nWeight Compliance Check: all axle and gross weights are within the DOT limits. You are good to go.',
    },
  },
};

const parse = (v) => {
  if (Array.isArray(v)) return v;
  try {
    const parsed = JSON.parse(v || '[]');
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
};

const apply = async (queryInterface, pick) => {
  const [flows] = await queryInterface.sequelize.query('SELECT id, name, actions FROM flows WHERE name IN (:names)', {
    replacements: { names: Object.keys(TEMPLATES) },
  });
  for (const flow of flows) {
    const byType = TEMPLATES[flow.name];
    const actions = parse(flow.actions).map((a) => (byType[a.type] ? { ...a, ...pick(byType[a.type], a) } : a));
    await queryInterface.sequelize.query('UPDATE flows SET actions = :actions, updatedAt = NOW() WHERE id = :id', {
      replacements: { actions: JSON.stringify(actions), id: flow.id },
    });
  }
};

module.exports = {
  async up(queryInterface) {
    await apply(queryInterface, (next) => next);
  },

  // The previous wording listed every weight; restoring it exactly is not needed to roll back the code
  async down() {},
};
