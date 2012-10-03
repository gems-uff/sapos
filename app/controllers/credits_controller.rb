class CreditsController < ApplicationController
  def show
    file_to_open = [Rails.root, 'README.md'].join(File::Separator)
    readme_file = File.open(file_to_open, "rb")
    file_content = readme_file.read

    @credits = file_content
  end

end
