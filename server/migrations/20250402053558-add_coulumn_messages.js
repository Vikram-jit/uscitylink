module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn("messages", "private_chat_id", {
      type: Sequelize.UUID,
      allowNull: true,
     
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn("messages", "private_chat_id");
  },
};
