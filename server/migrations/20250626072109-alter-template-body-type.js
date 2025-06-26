module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.changeColumn('templates', 'body', {
      type: Sequelize.TEXT('long'), // LONGTEXT equivalent
      allowNull: true,
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.changeColumn('templates', 'body', {
      type: Sequelize.STRING, // Revert to STRING if rolling back
      allowNull: true,
    });
  }
};