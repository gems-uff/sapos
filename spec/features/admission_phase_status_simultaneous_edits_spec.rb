# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Admission phase status: edições inline simultâneas", type: :feature, js: true do
  include AdmissionsScenarioHelpers
  before(:all) do
    @role_adm = FactoryBot.create(:role_administrador)
    @user = create_confirmed_user([@role_adm])
  end

  before(:each) do
    @template = create_admission_template("Inscrição", {
      "Foto" => {
        field_type: Admissions::FormField::STUDENT_FIELD,
        configuration: { "field" => "photo" }
      }
    })
    @process = create_closed_admission_process(
      @template, simple_url: "simultaneas-#{SecureRandom.hex(4)}"
    )
    @phase = add_phase(@process, 1)
    @application_a = create_application(@process, name: "Ana", admission_phase: @phase)
    @application_b = create_application(@process, name: "Bia", admission_phase: @phase)
    login_as(@user)
    @photo_field = @template.fields.find_by!(name: "Foto")
  end

  def sample_photo_path
    path = Rails.root.join("tmp", "spec_sample_photo_#{SecureRandom.hex(4)}.jpg")
    File.binwrite(path, "\xFF\xD8\xFF\xE0".b + ("x" * 200))
    path
  end

  def visit_candidate_list
    visit admission_applications_path(
      admission_process_id: @process.id, admission_phase_id: @phase.id, simple_view: "1"
    )
  end

  def edit_div_selector(application)
    "#as_admissions__admission_applications-#{application.id}-edit-div"
  end

  def open_override_edit(application)
    row = find("tr", text: application.name)

    within(row) do
      find(".advanced-config").click
      find(".edit-override").click
    end

    expect(page).to have_selector(edit_div_selector(application), wait: 10)
  end

  it "salva a candidatura aberta por último, com upload real, sem perder o dado nem gerar campo fantasma" do
    path = sample_photo_path
    visit_candidate_list
    open_override_edit(@application_a)
    open_override_edit(@application_b)

    edit_div = find(edit_div_selector(@application_b))

    within(edit_div) do
    check "Habilitar formulário nesta submissão"
    wait_for_ajax

    file_input = find(".webcam-photo input[type='file']", visible: false)

    attach_file(
      file_input[:id],
      path,
      make_visible: true
    )
  end

    form = edit_div.find(:xpath, "./ancestor::form")

    within(form) do
      submit = find(
        "input[type='submit'][value='Atualizar']",
        visible: :all
      )

      submit.click
      wait_for_ajax
    end

    expect(page).to have_no_selector(edit_div_selector(@application_b), wait: 10)

    b_photo_fields = @application_b.filled_form.reload.fields
      .where(form_field_id: @photo_field.id)

    expect(b_photo_fields.count).to eq(1)
    expect(b_photo_fields.first.file).to be_present

    # Nenhuma entrada órfã (sem form_field) foi persistida por engano.
    expect(@application_b.filled_form.fields.where(form_field_id: nil)).to be_empty

    expect(page).to have_selector(edit_div_selector(@application_a))
  ensure
    File.delete(path) if path && File.exist?(path)
  end

  it "usa um data-id diferente no widget de webcam de cada candidatura" do
    visit_candidate_list
    open_override_edit(@application_a)
    open_override_edit(@application_b)

    div_a = find("#{edit_div_selector(@application_a)} .webcam-photo", visible: :all)
    div_b = find("#{edit_div_selector(@application_b)} .webcam-photo", visible: :all)

    expect(div_a["data-id"]).not_to eq(div_b["data-id"])
  end
  it "habilitar o formulário de uma candidatura não libera o da outra" do
    visit_candidate_list
    open_override_edit(@application_a)
    open_override_edit(@application_b)

    within(edit_div_selector(@application_a)) do
      check "Habilitar formulário nesta submissão"
    end

    filename_a = find("#{edit_div_selector(@application_a)} input[name$='[file_][filename]']", visible: :all)
    filename_b = find("#{edit_div_selector(@application_b)} input[name$='[file_][filename]']", visible: :all)

    expect(filename_a.disabled?).to be false
    expect(filename_b.disabled?).to be true
  end
end
