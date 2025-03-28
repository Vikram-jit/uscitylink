module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn("group_messages", "url_upload_type", {
      type: Sequelize.ENUM("local", "server","not-upload","failed"),
      allowNull: false,
      defaultValue: "server",
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn("group_messages", "url_upload_type");
  },
};
