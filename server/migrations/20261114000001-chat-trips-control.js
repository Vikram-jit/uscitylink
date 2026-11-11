'use strict';

// Full control of a load: where a leg's miles came from (Samsara odometer or typed by dispatch, with
// why), and why a leg was cut (handed to another driver / truck mid-load).

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('chat_trips');
    if (!columns.miles_source) {
      await queryInterface.addColumn('chat_trips', 'miles_source', { type: Sequelize.STRING(10), allowNull: true, after: 'total_mileage' });
    }
    if (!columns.miles_note) {
      await queryInterface.addColumn('chat_trips', 'miles_note', { type: Sequelize.STRING(255), allowNull: true, after: 'miles_source' });
    }
    if (!columns.handover_reason) {
      await queryInterface.addColumn('chat_trips', 'handover_reason', { type: Sequelize.STRING(32), allowNull: true, after: 'ends_at_yard' });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('chat_trips', 'handover_reason');
    await queryInterface.removeColumn('chat_trips', 'miles_note');
    await queryInterface.removeColumn('chat_trips', 'miles_source');
  },
};
