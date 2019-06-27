class Form < ApplicationRecord
belongs_to :query
belongs_to :template, class_name: "FormTemplate"

validates_presence_of :nome
validates :query, :presence => true
validates :template, :presence => true

def to_label
  "#{self.nome}"
end

end
