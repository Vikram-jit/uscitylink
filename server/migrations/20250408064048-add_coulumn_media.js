module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn("media", "private_chat_id", {
      type: Sequelize.UUID,
      allowNull: true,
     
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn("media", "private_chat_id");
  },
};
