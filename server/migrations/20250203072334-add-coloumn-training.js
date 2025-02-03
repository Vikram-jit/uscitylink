module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('taining', 'duration', {
      type: Sequelize.STRING, 
      allowNull: true
    });

   
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('taining', 'duration');
    
  }
};
