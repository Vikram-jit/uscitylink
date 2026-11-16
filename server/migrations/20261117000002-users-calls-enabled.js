'use strict';

// Calling is switched on per driver: drivers only see the call options (dashboard card, chat call and
// video buttons) and may place calls when staff turn this on for them. Off for everyone at first.
// Staff can always call any driver, and drivers without it can still receive calls.

module.exports = {
  async up(queryInterface, Sequelize) {
    const columns = await queryInterface.describeTable('users');
    if (!columns.calls_enabled) {
      await queryInterface.addColumn('users', 'calls_enabled', { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('users', 'calls_enabled');
  },
};
