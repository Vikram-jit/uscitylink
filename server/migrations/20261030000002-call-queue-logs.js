'use strict';

// Dispatch call queue: how long the driver waited in line and until someone answered
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('calls', 'queued_sec', { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 });
    await queryInterface.addColumn('calls', 'wait_sec', { type: Sequelize.INTEGER, allowNull: true });
    await queryInterface.addColumn('calls', 'kind', { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'direct' });
  },
  down: async (queryInterface) => {
    await queryInterface.removeColumn('calls', 'kind');
    await queryInterface.removeColumn('calls', 'wait_sec');
    await queryInterface.removeColumn('calls', 'queued_sec');
  },
};
