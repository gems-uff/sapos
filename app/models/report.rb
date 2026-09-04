# frozen_string_literal: true

class Report < ApplicationRecord
  attr_accessor :document_title, :document_body, :expiration_in_months
  belongs_to :user, foreign_key: "generated_by_id"
  belongs_to :invalidated_by, foreign_key: "invalidated_by_id", class_name: "User", optional: true
  belongs_to :carrierwave_file, foreign_key: "carrierwave_file_id", class_name: "CarrierWave::Storage::ActiveRecord::ActiveRecordFile", optional: true

  validates :file_name, presence: true

  # O corte da validade e estrito: o rodape do PDF diz "Documento valido ate
  # <data>", entao o documento ainda vale no proprio dia do vencimento.
  #
  # O limite vive aqui e em nenhum outro lugar porque duas decisoes dependem
  # dele, em linguagens diferentes: o escopo filtra no banco o que a rotina de
  # limpeza apaga, o predicado responde por um registro na hora do download.
  # Foi a divergencia entre esses dois caminhos que a #631 fechou -- o sistema
  # servia o que o proprio documento negava --, e escrever o limite duas vezes
  # convidaria a divergencia de volta. spec/models/report_spec.rb prende escopo
  # e predicado ao mesmo corte.
  def self.expiry_cutoff
    Date.today
  end

  scope :expired, -> { where(expires_at: ...expiry_cutoff) }

  def to_label
    "#{self.user.name} - #{I18n.l(self.created_at, format: '%d/%m/%Y %H:%M')}"
  end

  def invalidate!(user:)
    carrierwave_file = self.carrierwave_file
    self.update!(carrierwave_file_id: nil, invalidated_by: user, invalidated_at: Time.now)
    carrierwave_file.delete
  end

  def expired?
    expires_at.present? && expires_at < self.class.expiry_cutoff
  end

  def expires_at_or_invalid
    if self.invalidated_at.present?
      I18n.t("activerecord.attributes.report.invalidated")
    else
      self.expires_at.present? ? I18n.l(self.expires_at, format: "%d/%m/%Y") : nil
    end
  end
end
