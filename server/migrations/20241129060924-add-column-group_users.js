module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn("group_users", "last_message_id", {
      type: Sequelize.UUID,
      allowNull: true,
      references: {
        model: "messages",
        key: "id",
      },
      onUpdate: "CASCADE",
      onDelete: "CASCADE",
    });

    await queryInterface.addColumn("group_users", "message_count", {
      type: Sequelize.INTEGER,
      defaultValue: 0,
    });

    await queryInterface.addColumn("group_users", "last_message_utc", {
      type: Sequelize.DATE,
      allowNull: true,
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.removeColumn("group_users", "last_message_id");
    await queryInterface.removeColumn("group_users", "message_count");

    await queryInterface.removeColumn("group_users", "last_message_utc");
  },
};
