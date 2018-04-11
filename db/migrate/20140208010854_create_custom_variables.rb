# encoding: utf-8

# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.
class CreateCustomVariables < ActiveRecord::Migration[5.1]
  def up
    CustomVariable.where(:variable => "single_advisor_points").first or CustomVariable.create(:name=>"Pontos para orientador único", :variable =>"single_advisor_points", :value => "1.0")
    CustomVariable.where(:variable => "multiple_advisor_points").first or CustomVariable.create(:name=>"Pontos para orientador múltiplo", :variable =>"multiple_advisor_points", :value => "0.5")
    CustomVariable.where(:variable => "program_level").first or CustomVariable.create(:name=>"Nível do Programa na CAPES", :variable =>"program_level", :value => "5")
    CustomVariable.where(:variable => "identity_issuing_country").first or CustomVariable.create(:name=>"País padrão de emissão da identidade", :variable =>"identity_issuing_country", :value => "Brasil")
    CustomVariable.where(:variable => "class_schedule_text").first or CustomVariable.create(:name=>"Texto no final do quadro de horários", :variable =>"class_schedule_text", :value => "Alunos interessados em cursar disciplinas de Tópicos Avançados devem consultar os respectivos professores antes da matrícula.")
    CustomVariable.where(:variable => "class_schedule_text").first or CustomVariable.create(:name=>"Texto no final do quadro de horários", :variable =>"class_schedule_text", :value => "Alunos interessados em cursar disciplinas de Tópicos Avançados devem consultar os respectivos professores antes da matrícula")
    CustomVariable.where(:variable => "redirect_email").first or CustomVariable.create(:name=>"E-mail de redirecionamento para as notificações", :variable =>"redirect_email", :value => "")
    CustomVariable.where(:variable => "notification_footer").first or CustomVariable.create(:name=>"Texto de rodapé da notificação", :variable =>"notification_footer", :value => "Pós-Graduação em Computação - IC/UFF
      Este e-mail foi enviado automaticamente pelo SAPOS. Por favor, não responda. 
      Em caso de dúvida, procure a secretaria."
    )
  end

  def down
  end
end
