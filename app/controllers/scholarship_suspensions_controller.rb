class ScholarshipSuspensionsController < ApplicationController
  authorize_resource
  active_scaffold :"scholarship_suspension" do |config|
  	config.columns[:scholarship_duration].form_ui = :record_select
  	config.columns = [:scholarship_duration, :start_date, :end_date, :active]
  end
end
