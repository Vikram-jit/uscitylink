"use strict";

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable("private_chat_members", {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
        allowNull: false,
      },
      userProfileId: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: "user_profiles",
          key: "id",
        },
        onUpdate: "CASCADE",
        onDelete: "CASCADE",
      },
      createdBy: {
        type: Sequelize.UUID,
        allowNull: false,
        references: {
          model: "user_profiles",
          key: "id",
        },
        onUpdate: "CASCADE",
        onDelete: "CASCADE",
      },

      senderCount: {
        type: Sequelize.INTEGER,
        defaultValue: 0,
      },
      reciverCount: {
        type: Sequelize.INTEGER,
        defaultValue: 0,
      },
      last_message_id: {
        type: Sequelize.UUID,
        allowNull: true,
        references: {
          model: "messages",
          key: "id",
        },
        onUpdate: "CASCADE",
        onDelete: "CASCADE",
      },
      status: {
        type: Sequelize.STRING,
        defaultValue: "active",
      },
      createdAt: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal("CURRENT_TIMESTAMP"),
      },
      updatedAt: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal(
          "CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
        ),
      },
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable("private_chat_members");
  },
};
