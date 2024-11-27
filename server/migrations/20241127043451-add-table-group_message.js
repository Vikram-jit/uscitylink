'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('group_messages', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4, // Automatically generate UUID
        primaryKey: true,
        allowNull: false,
      },
      groupId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'groups', 
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      senderId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'user_profiles', 
          key: 'id',
        },
      },
      body: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
     
      deliveryStatus: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      messageTimestampUtc: {
        type: Sequelize.DATE,
        allowNull: false,
      },
      createdAt: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updatedAt: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'),
      },
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('group_messages');
  },
};
