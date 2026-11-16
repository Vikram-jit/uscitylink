'use strict';

// The driver's real taps, kept on their own (never overwritten by dispatch's time corrections or the GPS
// match): when they tapped "Loaded — rolling" (start loading) and "Delivered — end trip". Miles are read between
// these two moments. And how far they were from the appointments, in minutes (+ late / - early) — saved
// separately; the appointments and the start / end times in the main columns are not touched.

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('chat_trips');
    const add = async (name, spec) => {
      if (!columns[name]) await queryInterface.addColumn('chat_trips', name, spec);
    };
    await add('rolling_tapped_at', { type: Sequelize.DATE, allowNull: true });
    await add('end_tapped_at', { type: Sequelize.DATE, allowNull: true });
    await add('pickup_diff_min', { type: Sequelize.INTEGER, allowNull: true });
    await add('drop_diff_min', { type: Sequelize.INTEGER, allowNull: true });
  },

  async down(queryInterface) {
    for (const c of ['drop_diff_min', 'pickup_diff_min', 'end_tapped_at', 'rolling_tapped_at']) await queryInterface.removeColumn('chat_trips', c);
  },
};
