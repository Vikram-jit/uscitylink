module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('media', 'thumbnail', {
      type: Sequelize.STRING, 
      allowNull: true
    });

    await queryInterface.addColumn('messages', 'thumbnail', {
      type: Sequelize.STRING, 
      allowNull: true
    });
    await queryInterface.addColumn('group_messages', 'thumbnail', {
      type: Sequelize.STRING, 
      allowNull: true
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('media', 'thumbnail');
    await queryInterface.removeColumn('messages', 'thumbnail');
   await queryInterface.removeColumn('group_messages', 'thumbnail');
    
  }
};