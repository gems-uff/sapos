class AddSuporteRole < ActiveRecord::Migration
    def self.up
        Role.create{:id => 7, name => "Suporte", :description => "Suporte (inserir fotos de alunos)"}
    end
end
