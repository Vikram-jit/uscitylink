'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('messages', 'isBroadcastMessage', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false, // 0
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('messages', 'isBroadcastMessage');
  },
};