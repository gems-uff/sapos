class ApplicationProcessesController < ApplicationController
  authorize_resource
  include ApplicationHelper
  include PdfHelper

  before_action :get_application_process_pdf, only: [:application_process_complete_pdf, :application_process_short_pdf]

  active_scaffold :application_process do |config|
    config.columns.add :student_applications_count
    config.columns.add :year_semester

    config.list.sorting = {:end_date => 'ASC'}
    config.list.columns = [:name, :year_semester,:start_date, :end_date, :student_applications_count]

    # config.columns[:student_applications].includes = [:students, :student_applications]
    config.columns[:student_applications].includes = nil

    config.columns = [
        :name,
        :start_date,
        :end_date,
        :year,
        :semester,
        :min_letters,
        :max_letters,
        :form_template,
        :letter_template,
        :student_applications_count
    ]

    config.nested.add_link(:student_applications)

    config.action_links.add 'application_process_short_pdf',
                            :label => "<i title='Resumo' class='fa fa-file-text-o'></i>".html_safe,
                            :page => true,
                            :type => :member,
                            :parameters => {:format => :pdf}
    config.action_links.add 'application_process_complete_pdf',
                            :label => "<i title='Relatório Completo' class='fa fa-book'></i>".html_safe,
                            :page => true,
                            :type => :member,
                            :parameters => {:format => :pdf}
    config.action_links.add 'application_process_complete_xls',
                            :label => "<i title='Relatório Completo em .xls' class='fa fa-book'></i>".html_safe,
                            :page => true,
                            :type => :member,
                            :parameters => {:format => :xlsx}

    config.action_links.add :disable, :type => :member, :crud_type => :update, :method => :put, :position => false, :label => "<i title='#{I18n.t('active_scaffold.delete_link')}' class='fa fa-trash-o'></i>".html_safe

    #config.columns[:student_applications].select_associated_columns = [:student_name, :student_cpf]

    config.create.label = :create_application_process_label
    config.columns[:form_template].form_ui = :select
    config.columns[:form_template].clear_link
    config.columns[:letter_template].form_ui = :select
    config.columns[:letter_template].clear_link
    config.create.columns = [:name, :year, :semester, :start_date, :end_date, :form_template, :letter_template, :min_letters, :max_letters]
    config.update.label = :update_application_process_label
    config.update.columns = [:name, :year, :semester, :start_date, :end_date, :min_letters, :max_letters]

    config.actions.exclude :deleted_records, :delete
  end

  def beginning_of_chain
    super.enabled
  end

  def disable
    process_action_link_action do |record|
      if record.update(:is_enabled => false)
        flash[:info] = "Edital #{record.name} - #{record.semester}.#{record.year} removido com sucesso"
      else
        flash[:error] = "Não foi possível remover Edital #{record.name} - #{record.semester}.#{record.year}"
      end
    end
  end

  def application_process_short_pdf

  end
  def application_process_complete_pdf

  end
  def application_process_complete_xls
    @application_process = ApplicationProcess.find(params[:id])
    respond_to do |format|
      format.xlsx
      # format.xlsx do
      #   send_data render_to_string, :filename => "#{I18n.t('pdf_content.application_processes.to_pdf.filename')} - #{@application_process.name}_#{@application_process.year_semester}.xlsx", :type => 'application/xlsx'
      # end
    end
  end

  private

  def get_application_process_pdf
    @application_process = ApplicationProcess.find(params[:id])
    respond_to do |format|
      format.pdf do
        send_data render_to_string, :filename => "#{I18n.t('pdf_content.application_processes.to_pdf.filename')} - #{@application_process.name}_#{@application_process.year_semester}.pdf", :type => 'application/pdf'
      end
    end
  end

end