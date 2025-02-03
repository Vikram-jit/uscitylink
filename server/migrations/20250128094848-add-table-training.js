'use strict';

module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.createTable('taining', {
      id: {
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
        primaryKey: true,
      },
      title: {
        type: Sequelize.STRING,
        allowNull: true,
       
      },
      description: {
        type: Sequelize.STRING,
        allowNull: true,
       
      },
      file_name: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      file_type: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      file_size: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      mime_type: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      key: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      thumbnail: {
        type: Sequelize.STRING,
        allowNull: true,
        
      },
      createdAt: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP'),
      },
      updatedAt: {
        type: Sequelize.DATE,
        allowNull: false,
        defaultValue: Sequelize.literal('CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP'),
      },
    });
  },

  down: async (queryInterface, Sequelize) => {
    await queryInterface.dropTable('taining');
  },
};
