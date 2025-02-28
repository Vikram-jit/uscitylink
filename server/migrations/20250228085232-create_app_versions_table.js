module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('app_versions', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      version: {
        type: Sequelize.STRING,
        allowNull: false,
      },
      buildNumber: {
        type: Sequelize.INTEGER,
        allowNull: false,
      },
      releaseNotes: {
        type: Sequelize.TEXT,
        allowNull: true,
        comment: 'Details about the update',
      },
      status: {
        type: Sequelize.ENUM('pending', 'active', 'deprecated'),
        allowNull: false,
        defaultValue: 'pending',
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
    await queryInterface.dropTable('app_versions');
  },
};
