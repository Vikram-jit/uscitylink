module.exports = {
  up: async (queryInterface, Sequelize) => {
   
   
    await queryInterface.addColumn('messages', 'driverPin', {
  
      type: Sequelize.ENUM("0", "1"),  
      allowNull: false, 
      defaultValue: "0"
    });

    await queryInterface.addColumn('messages', 'staffPin', {
      type: Sequelize.ENUM("0", "1"),  
      allowNull: false, 
      defaultValue: "0"
    });


  },

  down: async (queryInterface, Sequelize) => {
    

    await queryInterface.removeColumn('messages', 'driverPin');
    await queryInterface.removeColumn('messages', 'staffPin');
   
    
  }
};
