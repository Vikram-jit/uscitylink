'use strict';

// The load's invoice number. Optional when the load is added (dispatch confirms "continue without"),
// required before dispatch can mark the trip completed (services/trips/tripService.ts act "complete").

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('chat_trips');
    if (!columns.invoice_no) {
      await queryInterface.addColumn('chat_trips', 'invoice_no', { type: Sequelize.STRING(64), allowNull: true, after: 'trip_no' });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('chat_trips', 'invoice_no');
  },
};
