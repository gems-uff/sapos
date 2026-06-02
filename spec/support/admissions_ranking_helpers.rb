# frozen_string_literal: true

module AdmissionsRankingHelpers
  # Create admission applications for a process with values for ranking columns.
  #
  # Parameters:
  # - admission_process: Admissions::AdmissionProcess
  # - ranking_config: Admissions::RankingConfig
  # - values: Array of values. Each element can be a scalar (applies to the
  #   first ranking column) or a Hash mapping column_name => value for multiple
  #   columns.
  # - columns: Optional array of column names or hashes to consider (defaults
  #   to the first ranking column of the ranking_config). Each element may be
  #   a String (column name) or a Hash with keys `:name` and optional `:order`
  #   to specify ASC/DESC ordering for the ranking column.
  # - emails: Optional array of emails to assign to created applications.
  # - names: Optional array of names to assign to created applications.
  # - processes: Optional array of hashes to configure ranking_processes on the
  #   ranking_config. Each hash can include :vacancies, :group, :order, :step,
  #   and optionally :ranking_machine (a RankingMachine instance).
  #
  # Returns the created Applications array.
  def create_ranked_candidates(admission_process:, ranking_config:, values:, columns: nil, emails: nil, names: nil, processes: nil, destroy_later: nil)
    created = []
    to_destroy = []
    columns ||= [ranking_config.ranking_columns.first.name]

    # Normalize columns into specs: { name: ..., order: ... }
    column_specs = columns.map do |col|
      if col.is_a?(Hash)
        name = col[:name] || col["name"]
        order = col[:order] || col["order"]
        type = col[:type] || col["type"]
        { name: name.to_s, order: order, type: type }
      else
        { name: col.to_s, order: nil, type: nil  }
      end
    end

    # Ensure form fields exist for the columns and have the requested type
    fields = {}
    created_form_fields = []
    column_specs.each do |spec|
      f = Admissions::FormField.find_by(name: spec[:name])
      if f
        if spec[:type].present? && f.field_type != spec[:type]
          f.update!(field_type: spec[:type])
        end
      else
        attrs = { name: spec[:name] }
        attrs[:field_type] = spec[:type] if spec[:type].present?
        f = FactoryBot.create(:form_field, **attrs)
        created_form_fields << f
      end
      fields[spec[:name]] = f
    end

    # Ensure ranking_config has the requested ranking_columns and that the
    # ordering is set when provided.
    column_specs.each do |spec|
      rc = ranking_config.ranking_columns.detect { |c| c.name == spec[:name] }
      if rc
        if spec[:order].present?
          rc.update!(order: spec[:order])
        else
          rc.save! if rc.changed?
        end
      else
        rc = ranking_config.ranking_columns.create!(name: spec[:name], order: spec[:order] || Admissions::RankingColumn::ASC)
        to_destroy << rc
      end
    end
    # Ensure all ranking_columns are persisted so in-memory order changes are seen
    ranking_config.ranking_columns.each { |c| c.save! }
    ranking_config.save! if ranking_config.changed?


    # Configure ranking processes if provided
    if processes.present?
      # Remove existing processes to allow deterministic setup
      ranking_config.ranking_processes.delete_all
      processes.each do |proc_attrs|
        rm = proc_attrs[:ranking_machine] || FactoryBot.create(:ranking_machine)
        to_destroy << rm if proc_attrs[:ranking_machine].nil?
        rp = ranking_config.ranking_processes.build(
          ranking_machine: rm,
          vacancies: proc_attrs[:vacancies],
          group: proc_attrs[:group],
          order: proc_attrs[:order],
          step: proc_attrs[:step]
        )
        rp.save!
        to_destroy << rp
      end
    end

    values.each_with_index do |val, idx|
      email = emails && emails[idx] ? emails[idx] : "candidate#{Time.now.to_i}#{rand(1000)}#{idx}@example.com"
      name = names && names[idx] ? names[idx] : "Candidate#{idx}"
      app = FactoryBot.create(:admission_application, admission_process: admission_process, email: email, name: name)
      to_destroy << app

      if val.is_a?(Hash)
        val.each do |col_name, v|
          ff = fields[col_name.to_s] || FactoryBot.create(:form_field, name: col_name.to_s)
          fff = FactoryBot.create(:filled_form_field, filled_form: app.filled_form, form_field: ff, value: v)
          to_destroy << fff
        end
      else
        ff = fields[column_specs.first[:name]]
        fff = FactoryBot.create(:filled_form_field, filled_form: app.filled_form, form_field: ff, value: val)
        to_destroy << fff
      end

      created << app
    end

    # append created auxiliary objects to provided destroy_later or @destroy_later
    to_destroy.concat(created_form_fields) if defined?(created_form_fields) && created_form_fields.any?
    destroy_later.concat(to_destroy) if destroy_later.is_a?(Array)

    created
  end

  def expect_ranking_positions(ranking_config, candidates, expected_positions)
    expect(candidates.map { |candidate|
      value = Admissions::AdmissionRankingResult.find_by(
        admission_application_id: candidate.id,
        ranking_config_id: ranking_config.id,
      ).filled_position.value.to_i
      value.zero? ? nil : value
    }).to eq(expected_positions)
  end

  def expect_ranking_machines(ranking_config, candidates, expected_machines)
    expect(candidates.map { |candidate|
      Admissions::AdmissionRankingResult.find_by(
        admission_application_id: candidate.id,
        ranking_config_id: ranking_config.id,
      ).filled_machine.value
    }).to eq(expected_machines)
  end
end

RSpec.configure do |config|
  config.include AdmissionsRankingHelpers, type: :model
end
