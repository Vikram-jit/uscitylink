module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('media', 'upload_source', {
      type: Sequelize.STRING, 
      allowNull: false,
      defaultValue:"message" 
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('media', 'upload_source');
  }
};
