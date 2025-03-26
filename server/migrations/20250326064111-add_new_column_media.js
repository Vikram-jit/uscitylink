module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn("messages", "url_upload_type", {
      type: Sequelize.ENUM("local", "server","not-upload","failed"),
      allowNull: false,
      defaultValue: "not-upload",
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn("messages", "url_upload_type");
  },
};
