'use strict';

// A driver's lineup: the order dispatch wants their lined-up loads in (lower goes first). The next
// load offered when the current one is delivered is #1 (services/trips/lineup.ts, offerNextLoad).

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('chat_trips');
    if (!columns.queue_pos) {
      await queryInterface.addColumn('chat_trips', 'queue_pos', { type: Sequelize.INTEGER, allowNull: true, after: 'leg_no' });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('chat_trips', 'queue_pos');
  },
};
