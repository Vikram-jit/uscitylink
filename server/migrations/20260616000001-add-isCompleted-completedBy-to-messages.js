'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    await queryInterface.addColumn('messages', 'isCompleted', {
      type: Sequelize.BOOLEAN,
      allowNull: false,
      defaultValue: false,
    });

    await queryInterface.addColumn('messages', 'completedBy', {
      type: Sequelize.UUID,
      allowNull: true,
      references: {
        model: 'user_profiles',
        key: 'id',
      },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });
  },

  async down(queryInterface, Sequelize) {
    await queryInterface.removeColumn('messages', 'completedBy');
    await queryInterface.removeColumn('messages', 'isCompleted');
  },
};
