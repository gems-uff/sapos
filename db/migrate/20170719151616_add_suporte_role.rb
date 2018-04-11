class AddSuporteRole < ActiveRecord::Migration[5.1]
    def self.up
        Role.create(:id => 7, :name => "Suporte", :description => "Suporte (inserir fotos de alunos)")
    end
end
