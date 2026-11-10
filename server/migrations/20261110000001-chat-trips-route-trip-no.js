'use strict';

// The yard Route List entry is now created when dispatch marks a trip completed (not when the load
// is added). chat_trips.trip_no is the load's own number (L0047); route_trip_no is the yard trip id
// the Route List entry got (008821), next to driver_pay_details_id.

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('chat_trips');
    if (!columns.route_trip_no) {
      await queryInterface.addColumn('chat_trips', 'route_trip_no', { type: Sequelize.STRING, allowNull: true, after: 'driver_pay_details_id' });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('chat_trips', 'route_trip_no');
  },
};
