
module.exports = {
  up: async (queryInterface,Sequelize) => {
    await queryInterface.createTable('messages', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      channelId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'channels', // Table name
          key: 'id',
        },
      },
      userProfileId: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'user_profiles', // Table name
          key: 'id',
        },
      },
      groupId: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'groups', // Table name
          key: 'id',
        },
      },
      body: {
        type: Sequelize.TEXT,
        allowNull: false,
      },
      messageDirection: {
        type: Sequelize.ENUM('S', 'R'),
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
      senderId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: 'user_profiles', 
          key: 'id',
        },
      },
      isRead: {
        type: Sequelize.BOOLEAN,
        allowNull: false,
        defaultValue: false,
      },
      status: {
        type: Sequelize.STRING,
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

  down: async (queryInterface) => {
    await queryInterface.dropTable('messages');
  },
};
