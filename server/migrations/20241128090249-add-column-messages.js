module.exports = {
  up: async (queryInterface, Sequelize) => {
    await queryInterface.addColumn('messages', 'type', {
      type: Sequelize.ENUM('default', 'truck_group','group','staff_message'),  
      allowNull: false, 
      defaultValue: 'default'
    });
  },

  down: async (queryInterface, Sequelize) => {
    
    await queryInterface.removeColumn('messages', 'type');
  
    await queryInterface.sequelize.query('DROP TYPE IF EXISTS "enum_groups_type"');
  }
};
