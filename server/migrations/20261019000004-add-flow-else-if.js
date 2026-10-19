'use strict';

// ELSE IF branches for flows: [{ name, conditions, actions }], checked in order after IF fails
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('flows', 'else_if', { type: Sequelize.JSON, allowNull: true });
  },
  async down(queryInterface) {
    await queryInterface.removeColumn('flows', 'else_if');
  },
};
