# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class CreateForeignKeys < ActiveRecord::Migration[5.1]
  def self.up
    add_foreign_key "accomplishments", ["enrollment_id"], "enrollments", ["id"]
    add_foreign_key "accomplishments", ["phase_id"], "phases", ["id"]
    add_foreign_key "advisements", ["professor_id"], "professors", ["id"]
    add_foreign_key "advisements", ["enrollment_id"], "enrollments", ["id"]
    add_foreign_key "cities", ["state_id"], "states", ["id"]
    add_foreign_key "courses", ["level_id"], "levels", ["id"]
    add_foreign_key "courses", ["institution_id"], "institutions", ["id"]
    add_foreign_key "courses_students", ["course_id"], "courses", ["id"]
    add_foreign_key "courses_students", ["student_id"], "students", ["id"]
    add_foreign_key "deferral_types", ["phase_id"], "phases", ["id"]
    add_foreign_key "deferrals", ["enrollment_id"], "enrollments", ["id"]
    add_foreign_key "deferrals", ["deferral_type_id"], "deferral_types", ["id"]
    add_foreign_key "dismissals", ["enrollment_id"], "enrollments", ["id"]
    add_foreign_key "dismissals",
      ["dismissal_reason_id"], "dismissal_reasons", ["id"]
    add_foreign_key "enrollments", ["student_id"], "students", ["id"]
    add_foreign_key "enrollments", ["level_id"], "levels", ["id"]
    add_foreign_key "enrollments",
      ["enrollment_status_id"], "enrollment_statuses", ["id"]
    add_foreign_key "phase_durations", ["phase_id"], "phases", ["id"]
    add_foreign_key "phase_durations", ["level_id"], "levels", ["id"]
    add_foreign_key "professors", ["state_id"], "states", ["id"]
    add_foreign_key "professors", ["city_id"], "cities", ["id"]
    add_foreign_key "scholarship_durations",
      ["scholarship_id"], "scholarships", ["id"]
    add_foreign_key "scholarship_durations",
      ["enrollment_id"], "enrollments", ["id"]
    add_foreign_key "scholarships", ["level_id"], "levels", ["id"]
    add_foreign_key "scholarships", ["sponsor_id"], "sponsors", ["id"]
    add_foreign_key "scholarships",
      ["scholarship_type_id"], "scholarship_types", ["id"]
    add_foreign_key "scholarships", ["professor_id"], "professors", ["id"]
    add_foreign_key "states", ["country_id"], "countries", ["id"]
    add_foreign_key "students", ["country_id"], "countries", ["id"]
    add_foreign_key "students", ["state_id"], "states", ["id"]
    add_foreign_key "students", ["city_id"], "cities", ["id"]
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
