module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn("media", "upload_type", {
      type: Sequelize.ENUM("local", "server"),
      allowNull: false,
      defaultValue: "server",
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn("media", "upload_type");
  },
};
