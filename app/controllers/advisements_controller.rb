class AdvisementsController < ApplicationController
  active_scaffold :advisement do |config|    
    
    config.action_links.add 'to_pdf', :label => I18n.t('active_scaffold.to_pdf'), :page => true, :type => :collection
    
    #Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search
    
    #Adiciona coluna virtual para orientações ativas    
    config.columns.add :active,:co_advisor, :enrollment_number,:student_name,:level
    
    config.field_search.columns = [:professor, :enrollment_number,:level ,:student_name , :main_advisor, :active, :co_advisor]        
            
    config.columns[:enrollment_number].includes = [:enrollment]
    config.columns[:student_name].includes = [{:enrollment => :student}]
    
    config.columns[:active].search_sql = ""
    config.columns[:active].search_ui = :select
    config.columns[:co_advisor].search_sql = ""
    config.columns[:co_advisor].search_ui = :select
    config.columns[:enrollment_number].search_sql = "enrollments.enrollment_number"
    config.columns[:student_name].search_sql = "students.name"
    config.columns[:level].search_sql = "enrollments.level_id"
    config.columns[:level].search_ui = :select
    
    config.list.columns = [:professor, :enrollment_number, :student_name , :main_advisor, :active, :co_advisor]
    config.columns[:professor].sort_by :sql => "professors.name"
    config.columns[:enrollment_number].sort_by :sql => "enrollments.enrollment_number"
    config.columns[:active].sort_by :method => "active_order"
    config.columns[:co_advisor].sort_by :method => "co_advisor_order"
    config.columns[:student_name].sort_by :sql => "students.name"
    config.list.sorting = {:enrollment => 'ASC'}
    config.create.label = :create_advisement_label        
    config.columns[:professor].form_ui = :record_select
    config.columns[:enrollment].form_ui = :record_select
    config.create.columns = [:professor, :enrollment, :main_advisor]
    config.update.columns = [:professor, :enrollment, :main_advisor]    
    config.show.columns = [:professor, :enrollment, :main_advisor]
  end
  
  def self.condition_for_active_column(column, value, like_pattern)
    sql_actives = "enrollments.id IN(
      SELECT enrollments.id
      FROM enrollments
      LEFT OUTER JOIN dismissals
      ON dismissals.enrollment_id = enrollments.id
      WHERE dismissals.id IS NULL
    )"
    sql_not_actives = "enrollments.id IN(
      SELECT enrollments.id
      FROM enrollments
      LEFT OUTER JOIN dismissals
      ON dismissals.enrollment_id = enrollments.id
      WHERE dismissals.id IS NOT NULL
    )"
    sql_all = "enrollments.id IN(
      SELECT enrollments.id
      FROM enrollments
      LEFT OUTER JOIN dismissals
      ON dismissals.enrollment_id = enrollments.id   
    )"
    
    case value
      when "active" then sql_to_use = sql_actives
      when "not_active" then sql_to_use = sql_not_actives
      when "all" then sql_to_use = sql_all
      else sql_to_use = sql_all
    end
            
    [sql_to_use]
  end
  
  def self.condition_for_co_advisor_column(column, value, like_pattern)
    sql_sim = "enrollments.id IN(
                SELECT enrollments.id
                FROM enrollments
                LEFT OUTER JOIN advisements
                ON enrollments.id = advisements.enrollment_id
                WHERE advisements.main_advisor = FALSE
              )"
    sql_nao = "enrollments.id NOT IN(
                SELECT enrollments.id
                FROM enrollments
                LEFT OUTER JOIN advisements
                ON enrollments.id = advisements.enrollment_id
                WHERE advisements.main_advisor = FALSE
              )"
    sql_all = "professors.id IN(
                SELECT professors.id
                FROM professors
                LEFT OUTER JOIN advisements
                ON professors.id = advisements.professor_id
              )"
    
    case value
      when "all" then sql_to_use = sql_all
      when "nao" then sql_to_use = sql_nao
      when "sim" then sql_to_use = sql_sim
      else sql_to_use = sql_all
    end
    
    [sql_to_use]
  end
  
  def to_pdf
    pdf = Prawn::Document.new
      
    y_position = pdf.cursor

    pdf.image("#{Rails.root}/config/images/logoIC.jpg", :at => [455, y_position],
                                                           :vposition => :top,
                                                           :scale => 0.3
    )

    pdf.font("Courier", :size => 14) do
      pdf.text "Universidade Federal Fluminense
                Instituto de Computação
                Pós-Graduação"
    end

    pdf.move_down 30

    header = [["<b>Professor</b>",
               "<b>Número de Matrícula</b>",
               "<b>Aluno</b>",
               "<b>Nível</b>"]]
    pdf.table( header, :column_widths => [135, 135, 135, 135],
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
      adv.enrollment[:enrollment_number],
      adv.enrollment.student[:name],
      adv.enrollment.level[:name]
    ]
    end

    pdf.table( advs, :column_widths => [135, 135, 135, 135],
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
