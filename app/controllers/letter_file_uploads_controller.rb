
class LetterFileUploadsController < ApplicationController
  authorize_resource
  def download
    @file = LetterFileUpload.find(params[:id])
    send_file @file.file.path, :x_sendfile=>true
  end
end