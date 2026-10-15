'use strict';

const SEED_KEYWORDS = {
  scale_ticket: ['CAT Scale', 'certified weight', 'scale ticket', 'weigh number', 'steer axle', 'drive axle', 'trailer axle', 'gross weight', 'public weighmaster'],
  bol_pickup: ['bill of lading', 'shipper', 'consignee', 'carrier', 'seal', 'pieces', 'description of articles', 'shipper no'],
  pod_signed: ['received by', 'consignee receipt', 'received quantities', 'received above', 'over short damage', 'signature', 'delivered'],
  lumper_receipt: ['lumper', 'unloading', 'unload fee', 'comchek', 'efs'],
  fuel_receipt: ['diesel', 'gallons', 'price per gallon', 'pump', 'DEF', 'fuel'],
};

/** @type {import('sequelize-cli').Migration} */
module.exports = {
  async up(queryInterface, Sequelize) {
    const addColumn = async (table, column, definition) => {
      const existing = await queryInterface.describeTable(table);
      if (!existing[column]) await queryInterface.addColumn(table, column, definition);
    };
    await addColumn('doc_types', 'keywords', { type: Sequelize.JSON, allowNull: true });
    await addColumn('message_documents', 'text_found', { type: Sequelize.JSON, allowNull: true });
    await addColumn('message_documents', 'classified_by', { type: Sequelize.STRING(16), allowNull: true });
    await addColumn('message_documents', 'matched_keywords', { type: Sequelize.JSON, allowNull: true });

    // Starter keywords for the seeded types (never overwrites keywords an admin already set)
    for (const [key, words] of Object.entries(SEED_KEYWORDS)) {
      await queryInterface.sequelize.query(
        'UPDATE doc_types SET keywords = ? WHERE `key` = ? AND keywords IS NULL',
        { replacements: [JSON.stringify(words), key] },
      );
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('message_documents', 'matched_keywords');
    await queryInterface.removeColumn('message_documents', 'classified_by');
    await queryInterface.removeColumn('message_documents', 'text_found');
    await queryInterface.removeColumn('doc_types', 'keywords');
  },
};
