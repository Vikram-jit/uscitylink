'use strict';

// The driver answers a load: Accept / Reject. On a load that is only lined up (an "upcoming" load the driver
// sees in the app) "accepted" is remembered here, and the load is sent as already accepted when the driver's
// current load ends. "rejected" sends the load back to dispatch (no driver), with the driver's reason.

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('chat_trips');
    if (!columns.driver_response) {
      await queryInterface.addColumn('chat_trips', 'driver_response', { type: Sequelize.STRING(10), allowNull: true });
    }
    if (!columns.driver_response_at) {
      await queryInterface.addColumn('chat_trips', 'driver_response_at', { type: Sequelize.DATE, allowNull: true });
    }
    if (!columns.driver_response_note) {
      await queryInterface.addColumn('chat_trips', 'driver_response_note', { type: Sequelize.STRING(255), allowNull: true });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('chat_trips', 'driver_response_note');
    await queryInterface.removeColumn('chat_trips', 'driver_response_at');
    await queryInterface.removeColumn('chat_trips', 'driver_response');
  },
};
