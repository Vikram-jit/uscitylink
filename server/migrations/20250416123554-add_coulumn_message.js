module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn("messages", "temp_id", {
      type: Sequelize.TEXT,
      allowNull: true,
      defaultValue: null,
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn("messages", "temp_id");
  },
};
