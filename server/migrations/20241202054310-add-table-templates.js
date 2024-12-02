// migrations/[timestamp]-create-group.ts

module.exports  = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('templates', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4, // Automatically generate UUID
        primaryKey: true,
        allowNull: false,
      },
      channelId: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'channels', 
          key: 'id',
        },
      },
      userProfileId: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: 'user_profiles', 
          key: 'id',
        },
      },
      name: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      body: {
        type: Sequelize.STRING,
        allowNull: true,
      },
      url: {
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

  down: async (queryInterface) => {
    await queryInterface.dropTable('templates');
  },
};
