'use strict';

// Group calls: who asked each added person to join (call_participants.role = 'added')
module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('call_participants', 'invited_by', { type: Sequelize.UUID, allowNull: true });
  },
  down: async (queryInterface) => {
    await queryInterface.removeColumn('call_participants', 'invited_by');
  },
};
