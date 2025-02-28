module.exports = {
  up: async (queryInterface, Sequelize) => {
   
    await queryInterface.addColumn('user_profiles', 'version', {
      type: Sequelize.STRING, 
      allowNull: true
    });

    await queryInterface.addColumn('user_profiles', 'buildNumber', {
      type: Sequelize.STRING, 
      allowNull: true
    });
    await queryInterface.addColumn('user_profiles', 'appUpdate', {
      type: Sequelize.ENUM('0', '1'), // Enum values
      allowNull: true, // Can be NULL
      defaultValue: '0', // Optional default value
    });

  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('user_profiles', 'version');
    await queryInterface.removeColumn('user_profiles', 'buildNumber');
    await queryInterface.removeColumn('user_profiles', 'appUpdate');
    
  }
};
