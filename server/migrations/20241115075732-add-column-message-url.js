module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('messages', 'url', {
      type: Sequelize.STRING, 
      allowNull: true, 
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('messages', 'url');
  }
};
