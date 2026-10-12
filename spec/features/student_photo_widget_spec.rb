# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# O widget de webcam da foto do aluno e montado por JS: o _photo_widget emite um
# <div class="webcam-photo" data-id="..."> e chama carrierwave_webcam com um
# seletor; o widget le o data-id e injeta a partir dele os links "Webcam",
# "Arquivo" e "Tirar foto" e os hidden da captura. Se o seletor nao casar, a
# funcao devolve na primeira linha sem erro nenhum e os controles simplesmente
# nao aparecem.
#
# Nada disso e observavel sem navegador: o request spec de carrierwave so afirma
# que o corpo traz `carrierwave_controls` e um input de arquivo, e o
# students_spec anexa a foto pelo rotulo, o que funciona com ou sem o widget
# montado -- tanto que o cabecalho dele ainda diz "ToDo: webcam photo widget".
RSpec.describe "Cadastro de aluno: widget de foto", type: :feature, js: true do
  before(:each) do
    @role_adm = FactoryBot.create(:role_administrador)
    @user = create_confirmed_user([@role_adm])
    @student = FactoryBot.create(:student, name: "Ana", cpf: "111")
    login_as(@user)
  end

  it "monta os controles de webcam a partir do data-id do proprio campo" do
    visit edit_student_path(@student)

    container = find(".webcam-photo", visible: :all)
    id = container["data-id"]
    expect(id).to be_present

    # Os quatro elementos que carrierwave_webcam injeta a partir do data-id. Se
    # o seletor do partial nao casar com o container, nenhum deles existe.
    expect(page).to have_selector("##{id}_togglewebcam", visible: :all)
    expect(page).to have_selector("##{id}_togglefile", visible: :all)
    expect(page).to have_selector("##{id}_camera_inputs", visible: :all)
    expect(page).to have_selector("##{id}_takesnapshot", visible: :all)

    # E eles tem de estar dentro do container do campo, nao soltos na pagina.
    expect(container).to have_selector("##{id}_camera_inputs", visible: :all)
  end
end
