'use strict';

// Staff can mute push notifications from the app's Settings screen until this time (null = not muted)
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('user_profiles', 'notifications_muted_until', {
      type: Sequelize.DATE,
      allowNull: true,
    });
  },

  down: async (queryInterface) => {
    await queryInterface.removeColumn('user_profiles', 'notifications_muted_until');
  },
};
