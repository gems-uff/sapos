# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "spec_helper"

# Professor que lanca nota so pode mudar nota, situacao, reprovacao por falta e
# observacao. A recusa usa I18n.t(:changes_to_disallowed_fields) na raiz, mas a
# chave vive em activerecord.errors.messages: a mensagem sai "Translation
# missing". O CourseClass faz o mesmo com errors.add(:base, :chave), que acha.
RSpec.describe ClassEnrollment, "mensagem de campo nao permitido ao professor", type: :model do
  before(:each) do
    @inscricao = FactoryBot.create(:class_enrollment)
  end

  def valida_como_professor
    @inscricao.send(:professor_changed_only_valid_fields)
    @inscricao.errors.full_messages
  end

  # Controle: mudar so um campo do professor (a observacao) nao gera erro.
  it "aceita mudanca so nos campos do professor" do
    @inscricao.obs = "observacao"

    expect(valida_como_professor).to be_empty
  end

  it "explica a recusa em portugues", pending: "issue #727" do
    @inscricao.attendance = 1 if @inscricao.respond_to?(:attendance=)
    @inscricao.enrollment = FactoryBot.create(:enrollment)

    mensagens = valida_como_professor

    expect(mensagens.join).to include("houve modificação de campos não válidos")
    expect(mensagens.join).not_to include("Translation missing")
  end
end
