'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('message_staff', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      messageId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'messages', 
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      staffId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'user_profiles',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      driverId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'user_profiles',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      type:{
        type: Sequelize.ENUM('group', 'truck-group','chat'), 
        allowNull: true,
        defaultValue: 'chat', 
      },

      status:{
        type: Sequelize.ENUM('read', 'un-read'), 
        allowNull: true,
        defaultValue: 'un-read', 
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
    await queryInterface.dropTable('training_driver_questions');
  },
};

