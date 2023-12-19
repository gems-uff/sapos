# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class AddFormConditionFieldsToModelsThatUseIt < ActiveRecord::Migration[7.0]
  def change
    Admissions::FormCondition.where(model_type: "Admissions::AdmissionPhase")
      .group_by(&:model_id).each do |model_id, conditions|
        phase = Admissions::AdmissionPhase.find(model_id)
        if conditions.size == 1
          phase.update!(approval_condition_id: conditions[0].id)
        else
          phase.update!(approval_condition: Admissions::FormCondition.create(
            mode: Admissions::FormCondition::AND,
            form_conditions: conditions
          ))
        end
      end

    add_column :admission_committees, :form_condition_id, :integer
    add_index :admission_committees, :form_condition_id

    Admissions::FormCondition.where(model_type: "Admissions::AdmissionCommittee")
      .group_by(&:model_id).each do |model_id, conditions|
        committee = Admissions::AdmissionCommittee.find(model_id)
        if conditions.size == 1
          committee.update!(form_condition_id: conditions[0].id)
        else
          committee.update!(form_condition: Admissions::FormCondition.create(
            mode: Admissions::FormCondition::AND,
            form_conditions: conditions
          ))
        end
      end

    add_column :ranking_machines, :form_condition_id, :integer
    add_index :ranking_machines, :form_condition_id

    Admissions::FormCondition.where(model_type: "Admissions::RankingMachine")
      .group_by(&:model_id).each do |model_id, conditions|
        machine = Admissions::RankingMachine.find(model_id)
        if conditions.size == 1
          machine.update!(form_condition_id: conditions[0].id)
        else
          machine.update!(form_condition: Admissions::FormCondition.create(
            mode: Admissions::FormCondition::AND,
            form_conditions: conditions
          ))
        end
      end

    Admissions::FormField.where(field_type: "Consolidação")
      .or(Admissions::FormField.where(field_type: "Email")).each do |field|
        config = field.config_hash
        next if config["conditions"].nil?
        condition = nil
        if config["conditions"].size == 1
          condition = config["conditions"][0]
          condition["mode"] = "Condição"
        elsif config["conditions"].size > 1
          condition = {
            "mode": "E",
            "form_conditions": config["conditions"].map do |child|
              child["mode"] = "Condição"
              child
            end
          }
        end
        config.delete("conditions")
        config["condition"] = condition
        field.update!(configuration: JSON.dump(config))
      end
  end
end
