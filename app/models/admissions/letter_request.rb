# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

class Admissions::LetterRequest < ActiveRecord::Base
  has_paper_trail

  WAITING = record_i18n_attr("statuses.waiting")
  RECEIVED = record_i18n_attr("statuses.received")

  SHADOW_FIELDS = Set[
    "name", "email", "telephone", "status"
  ]
  SHADOW_FIELDS_MAP = SHADOW_FIELDS.index_by do |field|
    record_i18n_attr(field)
  end

  belongs_to :admission_application, optional: false,
    class_name: "Admissions::AdmissionApplication"

  belongs_to :filled_form, optional: false,
    class_name: "Admissions::FilledForm"

  validates :admission_application, presence: true
  validates :email, presence: true
  # O e-mail e para onde o link da carta viaja; como o da candidatura, e
  # conferido quando e novo ou alterado (AdmissionApplication).
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true,
    if: :email_address_changed?
  validates :email, length: { maximum: 255 }, if: :email_address_changed?

  before_validation :strip_email
  validates :name, presence: true

  before_save :set_access_token

  accepts_nested_attributes_for :filled_form, allow_destroy: true

  after_initialize :initialize_filled_form

  def initialize_filled_form
    return if self.admission_application.blank?
    self.filled_form ||= Admissions::FilledForm.new(
      is_filled: false,
      form_template: self.admission_application.admission_process.letter_template
    )
  end

  def status
    return WAITING if self.filled_form.blank? || !self.filled_form.is_filled
    RECEIVED
  end

  def is_filled
    return false if self.filled_form.blank?
    self.filled_form.is_filled
  end

  # O codigo de acesso e a credencial do recomendador, e viaja por e-mail para
  # o endereco do pedido. Quando quem edita a candidatura muda o endereco do
  # pedido, o codigo muda junto: quem tinha o antigo tinha a caixa antiga. A
  # carta ja preenchida nao troca de endereco -- o link novo abriria as
  # respostas do recomendador numa caixa escolhida por quem editou o pedido;
  # para trocar o recomendador dela, remove-se o pedido e cria-se outro.
  #
  # Quem chama e AdmissionApplication#assign_form, que atende o candidato e a
  # equipe, depois de aplicar o campo do pedido e o campo da carta sincronizado
  # com o e-mail; este volta junto com o endereco, senao a carta mostraria um
  # endereco e o pedido teria outro. A pagina publica da carta nao passa por
  # aqui: ali quem altera o e-mail e o proprio recomendador, que ja tem o
  # codigo.
  def follow_email_change
    return unless persisted? && email_address_changed?

    if answered?
      self.email = email_in_database
      filled_form.sync_fields_before(self)
    else
      self.access_token = generate_access_token
    end
  end

  # Se a carta ja esta respondida, pelo que esta gravado: durante a edicao da
  # candidatura a marca em memoria ja pode ser a da submissao em curso.
  def answered?
    Admissions::FilledForm.where(id: filled_form_id, is_filled: true).exists?
  end

  # Mudanca so de caixa ou de espaco em volta nao e outro endereco
  # (AdmissionApplication#email_address_changed?).
  def email_address_changed?
    email.to_s.strip.casecmp(email_in_database.to_s.strip) != 0
  end

  private
    # O espaco em volta nao e parte do endereco que chega; o gravado fica
    # como esta (AdmissionApplication#strip_email).
    def strip_email
      return unless email_changed?

      self.email = email.strip if email.is_a?(String) && email != email.strip
    end

    def generate_access_token
      token = SecureRandom.urlsafe_base64
      while Admissions::LetterRequest.exists?(access_token: token)
        token = SecureRandom.urlsafe_base64
      end
      token
    end

    def set_access_token
      unless self.access_token?
        self.access_token = generate_access_token
      end
    end
end
