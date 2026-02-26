'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
   await queryInterface.createTable("broadcast_messages", {
  id: {
    type: Sequelize.INTEGER,
    autoIncrement: true,
    primaryKey: true,
  },
  sender_id: {
    type: Sequelize.STRING,
    allowNull: false,
  },
  user_id: {
    type: Sequelize.STRING,
    allowNull: false,
  },
  body: {
    type: Sequelize.TEXT,
    allowNull: false,
  },
   url: {
    type: Sequelize.TEXT,
    allowNull: true,
  },
  status: {
    type: Sequelize.ENUM("pending", "processing", "sent", "failed"),
    defaultValue: "pending",
  },
  createdAt: Sequelize.DATE,
  updatedAt: Sequelize.DATE,
});

  },

  async down (queryInterface, Sequelize) {
        await queryInterface.dropTable("broadcast_messages");

  }
};
