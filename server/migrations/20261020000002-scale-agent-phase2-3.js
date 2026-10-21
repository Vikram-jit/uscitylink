'use strict';

// Scale agent phases 2 and 3 (client spec "AI CAT Scale Agent Training Spec" v1.0):
//   equipment_profiles: tractor/trailer axle layout, KPRA, tandem holes, ratings, measured lb-per-hole
//   driver_trips:       the route a driver is on (states + road class) and permits, entered by dispatch
//   weight_rule_sets:   + KPRA limit, bridge formula, review sign-off
//   scale_checks:       + route/equipment used, bridge and KPRA results, adjustment made, reweigh prediction
// Columns are added only when missing: the server's sequelize.sync() may have created a table first.

const addColumns = async (queryInterface, table, columns) => {
  const existing = await queryInterface.describeTable(table);
  for (const [name, spec] of Object.entries(columns)) {
    if (!existing[name]) await queryInterface.addColumn(table, name, spec);
  }
};

module.exports = {
  async up(queryInterface, Sequelize) {
    const tables = (await queryInterface.showAllTables()).map((t) => (typeof t === 'string' ? t : t.tableName));
    const timestamps = {
      createdAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
      updatedAt: { type: Sequelize.DATE, allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP') },
    };
    const num = { type: Sequelize.FLOAT, allowNull: true };
    const int = { type: Sequelize.INTEGER, allowNull: true };

    if (!tables.includes('equipment_profiles')) {
      await queryInterface.createTable('equipment_profiles', {
        id: { type: Sequelize.UUID, primaryKey: true },
        kind: { type: Sequelize.STRING(16), allowNull: false },
        unit_number: { type: Sequelize.STRING(64), allowNull: false },
        axle_count: int,
        // Tractor layout (feet)
        steer_to_drive_center_ft: num,
        drive_spread_ft: num,
        kingpin_to_drive_center_ft: num,
        fifth_wheel_range_in: num,
        // Trailer layout
        kpra_ft: num,
        trailer_spread_ft: num,
        length_ft: num,
        hole_spacing_in: num,
        holes_forward_available: int,
        holes_back_available: int,
        // Ratings (GAWR / tire) and GVWR
        steer_rating_lb: int,
        drive_rating_lb: int,
        trailer_rating_lb: int,
        gvwr_lb: int,
        // Measured weight shift per tandem hole, learned from reweighs
        lb_per_hole: num,
        lb_per_hole_samples: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 0 },
        notes: { type: Sequelize.TEXT, allowNull: true },
        active: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
        updated_by: { type: Sequelize.UUID, allowNull: true },
        ...timestamps,
      });
      await queryInterface.addIndex('equipment_profiles', ['kind', 'unit_number'], { unique: true });
    }

    if (!tables.includes('driver_trips')) {
      await queryInterface.createTable('driver_trips', {
        id: { type: Sequelize.UUID, primaryKey: true },
        driver_id: { type: Sequelize.UUID, allowNull: false },
        truck: { type: Sequelize.STRING(64), allowNull: true },
        trailer: { type: Sequelize.STRING(64), allowNull: true },
        origin: { type: Sequelize.STRING, allowNull: true },
        destination: { type: Sequelize.STRING, allowNull: true },
        segments: { type: Sequelize.JSON, allowNull: true },
        permits: { type: Sequelize.JSON, allowNull: true },
        cargo: { type: Sequelize.STRING, allowNull: true },
        status: { type: Sequelize.STRING(16), allowNull: false, defaultValue: 'active' },
        notes: { type: Sequelize.TEXT, allowNull: true },
        created_by: { type: Sequelize.UUID, allowNull: true },
        closed_at: { type: Sequelize.DATE, allowNull: true },
        ...timestamps,
      });
      await queryInterface.addIndex('driver_trips', ['driver_id', 'status']);
    }

    await addColumns(queryInterface, 'weight_rule_sets', {
      kpra_max_ft: num,
      bridge_formula: { type: Sequelize.BOOLEAN, allowNull: false, defaultValue: true },
      review_months: { type: Sequelize.INTEGER, allowNull: false, defaultValue: 12 },
      reviewed_at: { type: Sequelize.DATE, allowNull: true },
    });
    // California: 40 ft kingpin-to-rearmost-axle for 53 ft STAA trailers with 2+ rear axles (spec §4)
    await queryInterface.bulkUpdate('weight_rule_sets', { kpra_max_ft: 40 }, { jurisdiction: 'CA', kpra_max_ft: null });
    // The phase 1 seed citations said the bridge formula / KPRA were "not evaluated"; they are now
    await queryInterface.bulkUpdate('weight_rule_sets', { citation: '23 CFR 658.17; Federal Bridge Formula (23 U.S.C. 127)' }, { jurisdiction: 'FED', version: 1, citation: '23 CFR 658.17; Federal Bridge Formula (not evaluated: no axle spacing data)' });
    await queryInterface.bulkUpdate('weight_rule_sets', { citation: 'CVC 35550, 35551, 35551.5; KPRA 40 ft for 53 ft trailers with 2+ rear axles' }, { jurisdiction: 'CA', version: 1, citation: 'CVC 35550, 35551, 35551.5; KPRA 40 ft (2+ rear axles) not evaluated: no equipment data' });

    await addColumns(queryInterface, 'scale_checks', {
      trip_id: { type: Sequelize.UUID, allowNull: true },
      tractor_unit: { type: Sequelize.STRING(64), allowNull: true },
      trailer_unit: { type: Sequelize.STRING(64), allowNull: true },
      controlling_rules: { type: Sequelize.JSON, allowNull: true },
      bridge_results: { type: Sequelize.JSON, allowNull: true },
      kpra: { type: Sequelize.JSON, allowNull: true },
      adjustment_made: { type: Sequelize.JSON, allowNull: true },
      prediction: { type: Sequelize.JSON, allowNull: true },
    });
  },

  async down(queryInterface) {
    await queryInterface.dropTable('driver_trips');
    await queryInterface.dropTable('equipment_profiles');
    for (const c of ['kpra_max_ft', 'bridge_formula', 'review_months', 'reviewed_at']) {
      await queryInterface.removeColumn('weight_rule_sets', c).catch(() => {});
    }
    for (const c of ['trip_id', 'tractor_unit', 'trailer_unit', 'controlling_rules', 'bridge_results', 'kpra', 'adjustment_made', 'prediction']) {
      await queryInterface.removeColumn('scale_checks', c).catch(() => {});
    }
  },
};
