'use strict';

// Group calls: how an added person came in — 'add' (asked to join) or 'transfer' (the call was
// handed to them and whoever asked left)
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('call_participants', 'join_type', { type: Sequelize.STRING(16), allowNull: true });
  },
  down: async (queryInterface) => {
    await queryInterface.removeColumn('call_participants', 'join_type');
  },
};
