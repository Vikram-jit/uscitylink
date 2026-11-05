'use strict';

// Staff app: mute call alerts separately from message notifications (notifications_muted_until)
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('user_profiles', 'calls_muted_until', { type: Sequelize.DATE, allowNull: true });
  },
  down: async (queryInterface) => {
    await queryInterface.removeColumn('user_profiles', 'calls_muted_until');
  },
};
