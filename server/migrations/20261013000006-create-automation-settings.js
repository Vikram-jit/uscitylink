'use strict';

/** Key/value settings for the automation module (e.g. which AI model reads documents). */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = (await queryInterface.showAllTables()).map((t) => (typeof t === 'string' ? t : t.tableName));
    if (tables.includes('automation_settings')) return;
    await queryInterface.createTable('automation_settings', {
      key: { type: Sequelize.STRING(64), primaryKey: true },
      value: { type: Sequelize.TEXT, allowNull: true },
      updated_by: { type: Sequelize.UUID, allowNull: true },
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('automation_settings');
  },
};
