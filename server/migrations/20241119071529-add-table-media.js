'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('media', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4, 
        primaryKey: true,
        allowNull: false,
      },
      groupId: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'groups', 
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      channelId: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'channels',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      user_profile_id:{
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'user_profiles',
          key: 'id',
        },
        onUpdate: 'CASCADE',
        onDelete: 'CASCADE',
      },
      file_name: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      file_type: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      file_size: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      mime_type: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      key: {
        type: Sequelize.STRING,
        allowNull: true,
        
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
    await queryInterface.dropTable('media');
  },
};
