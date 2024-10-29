'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('user_profiles', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      userId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'users', 
          key: 'id',
        },
      },
      username: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      profile_pic: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      password: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      status: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      role_id: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'roles', // Assuming the table name is roles
          key: 'id',
        },
      },
      last_message_id: {
        type: Sequelize.INTEGER,
        allowNull: true,
      },
      isOnline: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false, 
      },
      device_id: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      device_token: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      platform: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      last_login: {
        type: Sequelize.DATE,
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
    await queryInterface.dropTable('user_profiles');
  }
};
