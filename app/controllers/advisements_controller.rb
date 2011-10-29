class AdvisementsController < ApplicationController
  active_scaffold :advisement do |config|    
    config.list.columns = [:professor, :enrollment, :main_advisor]    
    config.columns[:professor].sort_by :sql => 'professors.name'
    config.list.sorting = {:enrollment => 'ASC'}
    config.create.label = :create_advisement_label        
    config.columns[:professor].form_ui = :record_select
    config.columns[:enrollment].form_ui = :record_select
    config.create.columns = [:professor, :enrollment, :main_advisor]
    config.update.columns = [:professor, :enrollment, :main_advisor]    
  end
end 