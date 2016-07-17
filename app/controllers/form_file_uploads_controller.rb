class FormFileUploadsController < ApplicationController
  authorize_resource
  def download
    @file = FormFileUpload.find(params[:id])
    send_file @file.file.path, :x_sendfile=>true
  end
end