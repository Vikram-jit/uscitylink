module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('users', 'driver_number', {
      type: Sequelize.STRING, 
      allowNull: true
    });

   
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('users', 'driver_number');
    
  }
};
