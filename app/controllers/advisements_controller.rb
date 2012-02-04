class AdvisementsController < ApplicationController
  active_scaffold :advisement do |config|    
    
    config.action_links.add 'to_pdf', :label => I18n.t('active_scaffold.to_pdf'), :page => true, :type => :collection
    
    #Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search
    
    #Adiciona coluna virtual para orientações ativas    
    config.columns.add :active        
    
    config.field_search.columns = [:professor, :enrollment, :main_advisor, :active]        
            
    config.columns[:active].search_sql = ""
    
    config.list.columns = [:professor, :enrollment, :main_advisor]        
    config.columns[:professor].sort_by :sql => 'professors.name'
    config.list.sorting = {:enrollment => 'ASC'}
    config.create.label = :create_advisement_label        
    config.columns[:professor].form_ui = :record_select
    config.columns[:enrollment].form_ui = :record_select
    config.create.columns = [:professor, :enrollment, :main_advisor]
    config.update.columns = [:professor, :enrollment, :main_advisor]    
  end
  
  def self.condition_for_active_column(column, value, like_pattern)
    is_active = value == "true" 
    
#    TODO , como injetar SQL sem ser parametrizado
    sql_null = "enrollments.id IN(
      SELECT enrollments.id
      FROM enrollments
      LEFT OUTER JOIN dismissals
      ON dismissals.enrollment_id = enrollments.id
      WHERE dismissals.id IS NULL
    )"
    
    sql_not_null = "enrollments.id IN(
      SELECT enrollments.id
      FROM enrollments
      LEFT OUTER JOIN dismissals
      ON dismissals.enrollment_id = enrollments.id
      WHERE dismissals.id IS NOT NULL
    )"
            
    if is_active
      [sql_null]
    else
      [sql_not_null]
    end    
  end
  
  def to_pdf
    
    Prawn::Document.generate "relatorio.pdf" do |pdf|
      
      y_position = pdf.cursor

      # Tive que definir o lugar da foto manualmente... O :position => :right não estava
      # funcionando
      pdf.image( "#{Prawn::BASEDIR}/data/images/logoIC.jpg", :at => [455, y_position],
                                                             :vposition => :top,
                                                             :scale => 0.3
               )
      
      pdf.font("Courier", :size => 14) do
        pdf.text "Universidade Federal Fluminense
                  Instituto de Computação
                  Pós-Graduação"
      end

      pdf.move_down 30

      header = [["<b>Professor</b>","<b>Aluno</b>","<b>Nível</b>"]]
      pdf.table( header, :column_widths => [210, 210, 100],
                         :row_colors => ["BFBFBF"], 
                         :cell_style => { :font => "Courier", 
                                          :size => 10, 
                                          :inline_format => true, 
                                          :border_width => 0
                                        }
               )  

      each_record_in_page{}
      advisements = find_page().items
      
      advs = advisements.map do |adv|
      [
        adv.professor[:name],
        adv.enrollment.student[:name],
        adv.enrollment.level[:name]
      ]
      end
        
      pdf.table( advs, :column_widths => [210, 210, 100],
                       :row_colors => ["FFFFFF","F0F0F0"], 
                       :cell_style => { :font => "Courier", 
                                        :size => 8, 
                                        :inline_format => true,                                   
                                        :border_width => 0
                                      }
               )
      
      send_data(pdf.render, :filename => 'relatorio.pdf', :type =>'application/pdf')     
    
    end
    
  end
  
end 
