# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Parâmetros que a tela do candidato enviaria para um template qualquer (#681).
# Gera um valor válido por tipo de campo, sobrescritível por nome, para que um
# spec de fluxo preencha formulários reais de dezenas de campos sem enumerar
# cada um.
module AdmissionsCandidateHelpers
  PNG = Rails.root.join("spec", "fixtures", "user.png")

  # fields_attributes para um formulário do template, no formato dos nested
  # attributes. `values` mapeia nome do campo para valor (String, Array para
  # lista, ou Hash para scholarities). `existing` mapeia form_field_id para o
  # FilledFormField já gravado, quando o formulário está sendo editado.
  def candidate_fields_attributes(template, values = {}, existing: {})
    template.fields.order(:order, :id).each_with_index.to_h do |field, index|
      attrs = { form_field_id: field.id }
      attrs[:id] = existing[field.id].id if existing[field.id]
      value = values.key?(field.name) ? values[field.name] : default_candidate_value(field)
      case value
      when nil then nil
      when Array then attrs[:list] = value
      when Hash
        if value.key?(:scholarities)
          attrs[:scholarities_attributes] = value[:scholarities].each_with_index.to_h { |s, i| [i.to_s, s] }
        else
          attrs.merge!(value)
        end
      else attrs[:value] = value
      end
      [index.to_s, attrs]
    end
  end

  def default_candidate_value(field)
    configuration = field.config_hash
    case field.field_type
    when Admissions::FormField::HTML, Admissions::FormField::GROUP then nil
    when Admissions::FormField::STRING, Admissions::FormField::TEXT then "Texto de #{field.name}"
    when Admissions::FormField::NUMBER then "7"
    when Admissions::FormField::DATE then "01/02/2020"
    when Admissions::FormField::SELECT, Admissions::FormField::RADIO
      (configuration["values"] || ["Sim"]).first
    when Admissions::FormField::COLLECTION_CHECKBOX
      minimum = [configuration["minselection"].to_i, 1].max
      (configuration["values"] || ["Sim"]).first(minimum)
    when Admissions::FormField::SINGLE_CHECKBOX then "0"
    when Admissions::FormField::CITY then "Niterói <$> Rio de Janeiro <$> Brasil"
    when Admissions::FormField::RESIDENCY then "Rua das Flores <$> 10 <$> apto 1"
    when Admissions::FormField::FILE then upload_param(configuration["values"])
    when Admissions::FormField::SCHOLARITY then scholarity_param(configuration)
    when Admissions::FormField::STUDENT_FIELD then default_student_value(field, configuration)
    else "valor"
    end
  end

  def default_student_value(field, configuration)
    case configuration["field"]
    when "name" then nil # vem do nome da candidatura (sync)
    when "email" then nil
    when "photo" then upload_param(configuration["values"] || ["jpg"])
    when "birthdate" then "10/05/1998"
    when "identity_expedition_date" then "20/06/2016"
    when "special_city", "special_birth_city" then "Niterói <$> Rio de Janeiro <$> Brasil"
    when "special_address" then "Rua das Flores <$> 10 <$> apto 1"
    when "special_majors" then scholarity_param(configuration)
    when "cpf" then "#{rand(100..999)}.#{rand(100..999)}.#{rand(100..999)}-#{rand(10..99)}"
    else
      values = configuration["values"]
      values.present? ? values.first : "#{field.name} do candidato"
    end
  end

  def upload_param(extensions)
    extension = (extensions || ["pdf"]).first.delete_prefix(".")
    {
      file: {
        base64_contents: Base64.strict_encode64(File.binread(PNG)),
        filename: "documento.#{extension}",
      },
    }
  end

  def scholarity_param(configuration)
    {
      scholarities: [{
        level: (configuration["values"] || ["Graduação"]).first,
        status: (configuration["statuses"] || ["Concluído"]).last,
        institution: "UFF", course: "Computação", location: "Niterói",
        grade: "8.5", grade_interval: "0-10",
        start_date: "2015-03-01", end_date: "2019-12-15",
      }],
    }
  end

  # Inscrição completa pela rota pública, e devolve a candidatura. Edital com
  # sessão começa pela página do edital (nome e e-mail), que cria a candidatura
  # vazia e guarda o código na sessão; o formulário vem depois, por PUT. Sem
  # sessão, o POST do formulário cria tudo de uma vez.
  def apply_as_candidate(process, name:, email:, values: {}, letters: [])
    if process.require_session
      post admission_path(process.simple_url), params: { admissions_admission_application: { name: name, email: email } }
      application = Admissions::AdmissionApplication.find_by!(admission_process: process, email: email)
      expect(response).to redirect_to(edit_admission_apply_path(admission_id: process.simple_id, id: application.token))
    end
    # Campos sincronizados levam o nome e o e-mail de volta para a candidatura;
    # em branco, apagariam o que a página do edital gravou.
    synced = process.form_template.fields.where.not(sync: nil).to_h do |field|
      [field.name, { Admissions::FormField::SYNC_NAME => name, Admissions::FormField::SYNC_EMAIL => email,
                     Admissions::FormField::SYNC_TELEPHONE => "21999990000" }[field.sync]]
    end
    record = {
      name: name, email: email,
      filled_form_attributes: {
        enable_submission: "1",
        fields_attributes: candidate_fields_attributes(process.form_template, synced.merge(values)),
      },
    }
    record[:filled_form_attributes][:id] = application.filled_form.id if application
    if letters.present?
      record[:letter_requests_attributes] = letters.each_with_index.to_h { |letter, i| [i.to_s, letter] }
    end
    if application
      put admission_apply_path(admission_id: process.simple_id, id: application.token), params: { record: record }
    else
      post admission_apply_index_path(admission_id: process.simple_id), params: { record: record }
    end
    unless response.redirect?
      errors = Nokogiri::HTML(response.body).css(".errorExplanation, .form_errors, .error-message, .errors")
        .map(&:text).map(&:squish).reject(&:blank?)
      raise "inscrição de #{name} recusada: #{errors.presence || response.status}"
    end
    (application || Admissions::AdmissionApplication.find_by!(admission_process: process, email: email)).reload
  end

  # Carta de recomendação preenchida pela rota pública do recomendador.
  def fill_letter_as_recommender(process, letter_request, values = {})
    letter_request.filled_form.prepare_missing_fields
    put admission_letter_path(admission_id: process.simple_id, id: letter_request.access_token), params: {
      record: {
        name: letter_request.name, email: letter_request.email,
        filled_form_attributes: {
          id: letter_request.filled_form.id, enable_submission: "1",
          fields_attributes: candidate_fields_attributes(process.letter_template, values),
        },
      },
    }
    raise "carta de #{letter_request.name} recusada: #{response.status}" unless response.redirect?
    letter_request.reload
  end

  # Formulário de fase (compartilhado ou individual) gravado pela edição da
  # candidatura, como o membro do comitê faria. A tela manda o id do resultado
  # ou da avaliação quando ele já existe -- e ele costuma existir: ao abrir a
  # candidatura, o formulário de cada membro é construído e gravado vazio
  # junto com o que o primeiro membro salvou. Sem o id, o segundo membro
  # criaria uma avaliação duplicada e a validação de unicidade recusaria.
  def submit_phase_form(application, phase, template, values, mode: nil, user: nil, override: false)
    if mode
      key = :results_attributes
      attrs = { mode: mode, admission_phase_id: phase.id }
      existing = application.results.find_by(admission_phase: phase, mode: mode)
    else
      key = :evaluations_attributes
      attrs = { user_id: user.id, admission_phase_id: phase.id }
      existing = application.evaluations.find_by(admission_phase: phase, user: user)
    end
    existing_fields = existing ? existing.filled_form.fields.index_by(&:form_field_id) : {}
    attrs[:id] = existing.id if existing
    attrs[:filled_form_attributes] = {
      enable_submission: "1", form_template_id: template.id,
      fields_attributes: candidate_fields_attributes(template, values, existing: existing_fields),
    }
    attrs[:filled_form_attributes][:id] = existing.filled_form.id if existing
    params = { record: { key => { "0" => attrs } } }
    params[:can_edit_override] = "1" if override
    put admission_application_path(application), params: params, xhr: true
    raise "formulário de #{phase.name} recusado para #{application.name}: #{response.status}" unless response.status == 200
    saved = mode ? application.results.find_by(admission_phase: phase, mode: mode) :
      application.evaluations.find_by(admission_phase: phase, user: user)
    unless saved&.filled_form&.is_filled
      errors = Nokogiri::HTML(response.body.gsub("\\n", "\n")).text.scan(/[^.\n]*não pode[^.\n]*/).map(&:squish).uniq
      raise "formulário de #{phase.name} de #{application.name} não foi gravado: #{errors.presence || "sem erro na resposta"}"
    end
    saved
  end

  def consolidate_phase_as_staff(process, phase, **params)
    post consolidate_phase_admission_process_path(process),
      params: { consolidate_phase_id: phase&.id || 0 }.merge(params)
    raise "consolidação recusada: #{flash[:error]}" if flash[:error].present?
    flash[:info]
  end
end

RSpec.configure do |config|
  config.include AdmissionsCandidateHelpers, type: :request
end
