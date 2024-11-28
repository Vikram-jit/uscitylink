module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('group_messages', 'url', {
      type: Sequelize.STRING, 
      allowNull: true, 
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('group_messages', 'url');
  }
};
