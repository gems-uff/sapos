class ClassSchedulesController < ApplicationController
  authorize_resource
  helper :course_classes

  active_scaffold :"class_schedule" do |config|
    config.list.columns = [:year, :semester, :enrollment_start, :enrollment_end]
    config.create.columns = [:year, :semester, :enrollment_start, :enrollment_end]
    config.update.columns = [:year, :semester, :enrollment_start, :enrollment_end]
    config.create.label = :create_class_schedule_label
    config.update.label = :update_class_schedule_label

    config.action_links.add 'class_schedule_pdf', 
      :label => "<i title='#{I18n.t('pdf_content.course_class.class_schedule.link')}' class='fa fa-book'></i>".html_safe, 
      :page => true, 
      :type => :member, 
      :parameters => {:format => :pdf}

    config.actions.exclude :deleted_records

    config.columns[:year].form_ui = :select
    config.columns[:semester].form_ui = :select
    config.columns[:semester].options = {
      :options => CourseClass::SEMESTERS,
      :include_blank => true,
      :default => nil
    }
    config.columns[:year].options = {
      :options => CourseClass.selectable_years,
      :include_blank => true,
      :default => nil
    }
  end

  def class_schedule_pdf
    schedule = ClassSchedule.find(params[:id])
    if schedule.nil?
      flash[:error] = "Semestre não encontrado"
      return redirect_to action: :index
    end

    @year = schedule.year
    @semester = schedule.semester
    @course_classes = CourseClass.where(year: @year, semester: @semester)

    respond_to do |format|
      format.pdf do
        stream = render_to_string(:template => 'course_classes/class_schedule_pdf')
        send_data stream, :filename => "#{I18n.t("pdf_content.course_class.class_schedule.link")} (#{@year}_#{@semester}).pdf", :type => 'application/pdf'
      end
    end    
  end

end
