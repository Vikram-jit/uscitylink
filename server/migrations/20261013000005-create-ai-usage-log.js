'use strict';

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = (await queryInterface.showAllTables()).map((t) => (typeof t === 'string' ? t : t.tableName));
    if (!tables.includes('ai_usage_log')) {
      await queryInterface.createTable('ai_usage_log', {
        id: { type: Sequelize.UUID, defaultValue: Sequelize.UUIDV4, primaryKey: true },
        source: { type: Sequelize.STRING(16), allowNull: false }, // message | reread | sample | test | demo
        message_id: { type: Sequelize.UUID, allowNull: true },
        doc_type_key: { type: Sequelize.STRING(64), allowNull: true },
        model: { type: Sequelize.STRING(64), allowNull: false },
        input_tokens: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 }, // not served from cache
        cache_read_tokens: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        cache_write_tokens: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        output_tokens: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        cost_usd: { type: Sequelize.DECIMAL(12, 6), allowNull: false, defaultValue: 0 },
        latency_ms: { type: Sequelize.INTEGER, allowNull: true },
        created_by: { type: Sequelize.UUID, allowNull: true },
        createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
        updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      });
    }
    for (const fields of [['createdAt'], ['source']]) {
      try {
        await queryInterface.addIndex('ai_usage_log', fields);
      } catch (err) {
        if (!/Duplicate key name|already exists/i.test(err.message)) throw err;
      }
    }
  },

  async down(queryInterface) {
    await queryInterface.dropTable('ai_usage_log');
  },
};
