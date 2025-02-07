module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('training_drivers', 'quiz_result', {
      type: Sequelize.STRING, 
      allowNull: true
    });

   
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('training_drivers', 'quiz_result');
    
  }
};
