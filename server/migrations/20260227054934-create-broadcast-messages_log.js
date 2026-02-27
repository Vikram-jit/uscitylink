'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up (queryInterface, Sequelize) {
   await queryInterface.createTable("broadcast_message_logs", {
    id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4, // Automatically generate UUID
        primaryKey: true,
        allowNull: false,
      },
  
  body: {
    type: Sequelize.TEXT,
    allowNull: true,
  },
   url: {
    type: Sequelize.TEXT,
    allowNull: true,
  },
  totalMessages: {
    type: Sequelize.BIGINT,
    allowNull: false,
    defaultValue: 0,
  },
   sentMessages: {
    type: Sequelize.BIGINT,
    allowNull: false,
    defaultValue: 0,
  },
  createdAt: Sequelize.DATE,
  updatedAt: Sequelize.DATE,
});

  },

  async down (queryInterface, Sequelize) {
        await queryInterface.dropTable("broadcast_message_logs");

  }
};
