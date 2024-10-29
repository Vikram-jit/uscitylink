'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn('users', 'password');
    await queryInterface.removeColumn('users', 'username');
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('users', 'password', {
      type: Sequelize.STRING, // Adjust the type as needed
      allowNull: true // or false, based on your requirements
    });
    await queryInterface.addColumn('users', 'username', {
      type: Sequelize.STRING, // Adjust the type as needed
      allowNull: true // or false, based on your requirements
    });
  }
};
