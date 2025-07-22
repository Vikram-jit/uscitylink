module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn("media", "temp_id", {
      type: Sequelize.TEXT,
      allowNull: true,
      defaultValue: null,
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn("media", "temp_id");
  },
};
