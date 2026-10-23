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

  # Libera o armazenamento do documento. A limpeza de vencidos
  # (maintenance:remove_expired_reports) e invalidate! passam por aqui para
  # nao divergirem.
  #
  # Nenhuma FK garante que carrierwave_file_id aponte para uma linha que ainda
  # existe -- schema_plus_alternative.rb anula o add_foreign_key --, dai o `&.`:
  # sem ele, o NoMethodError derrubava a rake antes das notificacoes (#696).
  #
  # A transacao faz os dois passos acontecerem juntos ou nenhum. Sem ela, uma
  # falha ao apagar depois do update! deixaria o report sem arquivo e a linha
  # em carrier_wave_files orfa, que nenhuma rotina varre.
  def release_file!(**attributes)
    transaction do
      file = self.carrierwave_file
      if file.nil? && carrierwave_file_id.present?
        Rails.logger.warn "[Reports] Report #{id}: carrierwave_file_id " \
                           "#{carrierwave_file_id} sem linha em carrier_wave_files"
      end
      self.update!(carrierwave_file_id: nil, **attributes)
      file&.delete
    end
  end

  def invalidate!(user:)
    release_file!(invalidated_by: user, invalidated_at: Time.now)
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
