# encoding: utf-8
class ScholarshipsController < ApplicationController
  active_scaffold :scholarship do |config|
    config.action_links.add 'to_pdf', :label => I18n.t('active_scaffold.to_pdf'), :page => true, :type => :collection
    
    #Enables advanced search A.K.A FieldSearch
    config.actions.swap :search, :field_search
    
    config.list.sorting = {:scholarship_number => 'ASC'}
    config.list.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :start_date, :end_date]
    
    config.field_search.columns = [:scholarship_number ,:level, :sponsor, :scholarship_type, :start_date, :end_date]
    
    config.create.label = :create_scholarship_label
    
    config.columns[:start_date].search_sql = "scholarships.start_date"
    config.columns[:end_date].search_sql = "scholarships.end_date"
    config.columns[:scholarship_number].search_ui = :text
    
    config.columns[:sponsor].form_ui = :select
    config.columns[:scholarship_type].form_ui = :select
    config.columns[:level].form_ui = :select
    config.columns[:professor].form_ui = :record_select
    config.columns[:scholarship_type].clear_link
    config.columns[:level].clear_link
    config.columns[:sponsor].clear_link
    
    config.columns[:start_date].options = {:format => :monthyear}
    config.columns[:end_date].options = {:format => :monthyear}
    
    config.create.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :professor, :start_date, :end_date, :obs, :enrollments]
    config.update.columns = [:scholarship_number, :level, :sponsor, :scholarship_type, :professor, :start_date, :end_date, :obs, :enrollments]
    config.show.columns =   [:scholarship_number, :level, :sponsor, :scholarship_type, :professor, :start_date, :end_date, :obs, :enrollments]
  end
  record_select :per_page => 10, :search_on => [:scholarship_number], :order_by => 'scholarship_number', :full_text_search => true
  
  def self.condition_for_start_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty?  ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i,month.to_i)

      ["#{column.search_sql} >= ?", date]
    end
  end
  
  def self.condition_for_end_date_column(column, value, like_pattern)
    month = value[:month].empty? ? 1 : value[:month]
    year = value[:year].empty?  ? 1 : value[:year]

    if year != 1
      date = Date.new(year.to_i,month.to_i)

      ["#{column.search_sql} >= ?", date]
    end
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

    header = [["<b>Número da Bolsa</b>","<b>Nível</b>","<b>Agência</b>","<b>Tipo</b>","<b>Data de Início</b>","<b>Data de Fim</b>"]]
    pdf.table( header, :column_widths => [110, 70, 80, 70, 100 ,100],
                       :row_colors => ["BFBFBF"], 
                       :cell_style => { :font => "Courier", 
                                        :size => 10, 
                                        :inline_format => true, 
                                        :border_width => 0
                                      }
    )  

    each_record_in_page{}
    scholarships_from_page = find_page(:sorting => active_scaffold_config.list.user.sorting).items
    
    scholarships = scholarships_from_page.map! do |s| 
        [
          s[:scholarship_number],
          s.level.nil? ? nil : s.level[:name],
          s.sponsor.nil? ? nil : s.sponsor[:name],
          s.scholarship_type.nil? ? nil : s.scholarship_type[:name],
          s[:start_date].nil? ? nil : I18n.l(s[:start_date], :format => :monthyear),
          s[:end_date].nil? ? nil : I18n.l(s[:end_date], :format => :monthyear)
        ] 
    end

    pdf.table( scholarships, :column_widths => [110, 70, 80, 70, 100 ,100],
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