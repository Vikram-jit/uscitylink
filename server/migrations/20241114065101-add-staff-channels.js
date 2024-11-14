'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('staff_channels', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4, // Automatically generate UUID
        primaryKey: true,
        allowNull: false,
      },
      userProfileId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'user_profiles', 
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      channelId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'channels',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      isGroup: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false, 
      },
      recieve_message_count:{
        type: Sequelize.INTEGER,
        defaultValue: 0,  
      },
      isAccess:{
        type: Sequelize.INTEGER,
        defaultValue: 1,  
      },
      status:{
        type: Sequelize.STRING,
        defaultValue: "active", 
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
    await queryInterface.dropTable('staff_channels');
  },
};
