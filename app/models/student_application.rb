class StudentApplication < ActiveRecord::Base
  belongs_to :application_process
  has_many :form_field_inputs, :dependent => :delete_all
  has_many :form_text_inputs, :dependent => :delete_all
  has_many :letter_requests, :dependent => :delete_all
  has_many :form_file_uploads, :dependent => :delete_all

  accepts_nested_attributes_for :form_field_inputs,
                                allow_destroy: true
  accepts_nested_attributes_for :letter_requests,
                                allow_destroy: true
  accepts_nested_attributes_for :form_text_inputs,
                                allow_destroy: true
  accepts_nested_attributes_for :form_file_uploads,
                                allow_destroy: true

end
