'use strict';

// Loads with legs. A load (tracked by its invoice #) is moved by one or more legs; each leg is a
// chat_trips row run by one driver with their own truck / trailer / stops (pickup → yard → another
// driver → delivery, relays at a meet point, trailer moves). Every existing trip becomes a one-leg
// "direct" load with the same number and invoice #.

module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = await queryInterface.showAllTables();
    if (!tables.includes('chat_loads')) {
      await queryInterface.createTable('chat_loads', {
        id: { type: Sequelize.BIGINT.UNSIGNED, autoIncrement: true, primaryKey: true },
        load_no: { type: Sequelize.STRING(32), allowNull: true },
        invoice_no: { type: Sequelize.STRING(64), allowNull: true },
        // direct | via_yard | relay | trailer_move
        type: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'direct' },
        // scheduled | waiting | active | transfer | delivered | completed | cancelled (from its legs)
        status: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'scheduled' },
        notes: { type: Sequelize.TEXT, allowNull: true },
        created_by: { type: Sequelize.STRING(64), allowNull: true },
        created_by_name: { type: Sequelize.STRING, allowNull: true },
        created_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
        updated_at: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      });
      await queryInterface.addIndex('chat_loads', ['invoice_no']);
      await queryInterface.addIndex('chat_loads', ['load_no']);
      await queryInterface.addIndex('chat_loads', ['status']);
    }

    const columns = await queryInterface.describeTable('chat_trips');
    if (!columns.load_id) {
      await queryInterface.addColumn('chat_trips', 'load_id', { type: Sequelize.BIGINT.UNSIGNED, allowNull: true, after: 'id' });
      await queryInterface.addIndex('chat_trips', ['load_id']);
    }
    if (!columns.leg_no) {
      await queryInterface.addColumn('chat_trips', 'leg_no', { type: Sequelize.INTEGER, allowNull: false, defaultValue: 1, after: 'load_id' });
    }
    if (!columns.ends_at_yard) {
      await queryInterface.addColumn('chat_trips', 'ends_at_yard', { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: false, after: 'leg_no' });
    }
    if (!columns.planned_eta_at) {
      await queryInterface.addColumn('chat_trips', 'planned_eta_at', { type: Sequelize.DATE, allowNull: true, after: 'planned_start_at' });
    }

    // Every trip without a load becomes a one-leg direct load (same number, same invoice #)
    const [trips] = await queryInterface.sequelize.query(
      `SELECT id, trip_no, invoice_no, status, notes, created_by, created_by_name, created_at FROM chat_trips WHERE load_id IS NULL`
    );
    const statusOf = (s) =>
      s === 'cancelled' ? 'cancelled'
        : ['completed', 'routed'].includes(s) ? 'completed'
          : ['ended', 'paperwork'].includes(s) ? 'delivered'
            : s === 'offered' ? 'waiting'
              : s === 'scheduled' ? 'scheduled'
                : 'active';
    for (const t of trips) {
      const [id] = await queryInterface.sequelize.query(
        `INSERT INTO chat_loads (load_no, invoice_no, type, status, created_by, created_by_name, created_at, updated_at)
         VALUES (:loadNo, :invoice, 'direct', :status, :by, :byName, :at, NOW())`,
        { replacements: { loadNo: t.trip_no, invoice: t.invoice_no, status: statusOf(t.status), by: t.created_by, byName: t.created_by_name, at: t.created_at } }
      );
      await queryInterface.sequelize.query(`UPDATE chat_trips SET load_id = :load, leg_no = 1 WHERE id = :id`, { replacements: { load: id, id: t.id } });
    }
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('chat_trips', 'planned_eta_at');
    await queryInterface.removeColumn('chat_trips', 'ends_at_yard');
    await queryInterface.removeColumn('chat_trips', 'leg_no');
    await queryInterface.removeColumn('chat_trips', 'load_id');
    await queryInterface.dropTable('chat_loads');
  },
};
