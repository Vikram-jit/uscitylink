'use strict';

const { randomUUID } = require('crypto');

// CAT scale ticket compliance agent (client spec "AI CAT Scale Agent Training Spec" v1.0, phase 1):
//   weight_rule_sets: audited, versioned legal limits (never edited in place; an edit is a new version)
//   scale_checks:     one row per scale ticket, the spec's JSON output contract plus approval audit
// Also switches off the "Scale ticket — weight check" flow: the agent replies to scale tickets now.

const COMMON = {
  road_class: 'interstate',
  single_axle_lb: 20000,
  tandem_lb: 34000,
  gross_lb: 80000,
  // Company planning target, NOT a federal legal limit (spec §1)
  steer_target_lb: 12000,
  sum_tolerance_lb: 100,
  min_confidence: 0.8,
};

const SEED = [
  {
    ...COMMON,
    jurisdiction: 'FED',
    name: 'Federal Interstate baseline',
    citation: '23 CFR 658.17; Federal Bridge Formula (23 U.S.C. 127)',
    source_url: 'https://ops.fhwa.dot.gov/freight/publications/brdg_frm_wghts/index.htm',
  },
  {
    ...COMMON,
    jurisdiction: 'CA',
    name: 'California standard chart',
    citation: 'CVC 35550, 35551, 35551.5; KPRA 40 ft for 53 ft trailers with 2+ rear axles',
    source_url: 'https://dot.ca.gov/programs/traffic-operations/legal-truck-access/weight-limitation',
  },
];

module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = (await queryInterface.showAllTables()).map((t) => (typeof t === 'string' ? t : t.tableName));
    const timestamps = {
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    };

    if (!tables.includes('weight_rule_sets')) {
      await queryInterface.createTable('weight_rule_sets', {
        id: { type: Sequelize.UUID, primaryKey: true },
        jurisdiction: { type: Sequelize.STRING(16), allowNull: false },
        road_class: { type: Sequelize.STRING(32), allowNull: false, defaultValue: 'interstate' },
        version: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 1 },
        name: { type: Sequelize.STRING, allowNull: false },
        single_axle_lb: { type: Sequelize.INTEGER, allowNull: false },
        tandem_lb: { type: Sequelize.INTEGER, allowNull: false },
        gross_lb: { type: Sequelize.INTEGER, allowNull: false },
        steer_target_lb: { type: Sequelize.INTEGER, allowNull: true },
        sum_tolerance_lb: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 100 },
        min_confidence: { type: Sequelize.FLOAT, allowNull: false, defaultValue: 0.8 },
        citation: { type: Sequelize.TEXT, allowNull: true },
        source_url: { type: Sequelize.STRING(512), allowNull: true },
        effective_date: { type: Sequelize.DATEONLY, allowNull: true },
        reviewed_by: { type: Sequelize.UUID, allowNull: true },
        notes: { type: Sequelize.TEXT, allowNull: true },
        active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        ...timestamps,
      });
      await queryInterface.addIndex('weight_rule_sets', ['jurisdiction', 'road_class', 'version'], { unique: true });
    }

    // Seed separately from table creation: the server's sequelize.sync() can create an empty table
    // from the model before this migration runs
    const [existing] = await queryInterface.sequelize.query('SELECT jurisdiction FROM weight_rule_sets');
    const have = new Set(existing.map((r) => r.jurisdiction));
    const today = new Date().toISOString().slice(0, 10);
    const missing = SEED.filter((r) => !have.has(r.jurisdiction));
    if (missing.length) {
      await queryInterface.bulkInsert(
        'weight_rule_sets',
        missing.map((r) => ({ id: randomUUID(), version: 1, effective_date: today, active: true, createdAt: new Date(), updatedAt: new Date(), ...r })),
      );
    }

    if (!tables.includes('scale_checks')) {
      await queryInterface.createTable('scale_checks', {
        id: { type: Sequelize.UUID, primaryKey: true },
        message_id: { type: Sequelize.UUID, allowNull: false, unique: true },
        message_document_id: { type: Sequelize.UUID, allowNull: true },
        driver_id: { type: Sequelize.UUID, allowNull: true },
        channel_id: { type: Sequelize.UUID, allowNull: true },
        truck: { type: Sequelize.STRING(64), allowNull: true },
        ticket_number: { type: Sequelize.STRING(64), allowNull: true },
        measured_weights: { type: Sequelize.JSON, allowNull: true },
        confidence: { type: Sequelize.FLOAT, allowNull: true },
        image_quality: { type: Sequelize.STRING(16), allowNull: true },
        rule_set_id: { type: Sequelize.UUID, allowNull: true },
        rule_set_version: { type: Sequelize.STRING(64), allowNull: true },
        model: { type: Sequelize.STRING(64), allowNull: true },
        status: { type: Sequelize.STRING(32), allowNull: false },
        flags: { type: Sequelize.JSON, allowNull: true },
        group_overages_lb: { type: Sequelize.JSON, allowNull: true },
        headroom_lb: { type: Sequelize.JSON, allowNull: true },
        feasible_adjustments: { type: Sequelize.JSON, allowNull: true },
        assumptions: { type: Sequelize.JSON, allowNull: true },
        required_actions: { type: Sequelize.JSON, allowNull: true },
        driver_message: { type: Sequelize.TEXT, allowNull: true },
        previous_check_id: { type: Sequelize.UUID, allowNull: true },
        reweigh_check_id: { type: Sequelize.UUID, allowNull: true },
        approval_status: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'not_required' },
        approved_by: { type: Sequelize.UUID, allowNull: true },
        approved_at: { type: Sequelize.DATE, allowNull: true },
        approval_note: { type: Sequelize.TEXT, allowNull: true },
        ...timestamps,
      });
      await queryInterface.addIndex('scale_checks', ['driver_id', 'createdAt']);
      await queryInterface.addIndex('scale_checks', ['approval_status', 'createdAt']);
    }

    await queryInterface.bulkUpdate('flows', { active: false, updatedAt: new Date() }, { name: 'Scale ticket — weight check' });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('scale_checks');
    await queryInterface.dropTable('weight_rule_sets');
  },
};
