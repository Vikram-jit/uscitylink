module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn("groups", "last_message_id", {
      type: Sequelize.UUID,
      allowNull: true,
      references: {
        model: "messages",
        key: "id",
      },
      onUpdate: "CASCADE",
      onDelete: "CASCADE",
    });

    await queryInterface.addColumn("groups", "message_count", {
      type: Sequelize.INTEGER,
      defaultValue: 0,
    });   
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn("groups", "last_message_id");
    await queryInterface.removeColumn("groups", "message_count");

  },
};
