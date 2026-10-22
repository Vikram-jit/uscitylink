'use strict';

// Admin → App versions: "Force update" — users on an older build of that platform must update
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('app_versions', 'force_update', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    });
  },

  down: async (queryInterface) => {
    await queryInterface.removeColumn('app_versions', 'force_update');
  },
};
