module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('app_versions', 'platform', {
      type: Sequelize.STRING, 
      allowNull: true
    });

   

  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('app_versions', 'version');
   
    
  }
};
