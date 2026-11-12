'use strict';

// A load dispatch lined up "after the driver's current load" goes out by itself the moment the driver
// ends that load (Delivered) — no waiting for Mark completed or another confirm.

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('chat_trips');
    if (!columns.auto_send) {
      await queryInterface.addColumn('chat_trips', 'auto_send', { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false, after: 'queue_pos' });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('chat_trips', 'auto_send');
  },
};
