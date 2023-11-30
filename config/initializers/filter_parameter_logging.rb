# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Configure parameters to be filtered from the log file. Use this to limit dissemination of
# sensitive information. See the ActiveSupport::ParameterFilter documentation for supported
# notations and behaviors.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
]

# Override of render_bind to force a truncation of the binary column of carrier_wave_files
# https://github.com/rails/rails/blob/master/activerecord/lib/active_record/log_subscriber.rb#L86
module LogTruncater
  def render_bind(attr, value)
    case attr
    when ActiveModel::Attribute
      if attr.type.binary? && attr.value
        value = "<#{attr.value_for_database.to_s.bytesize} bytes of binary data>"
      # new code
      elsif attr.name.to_s == "binary" && attr.value
        value = "<#{attr.value_for_database.to_s.bytesize} bytes of binary data>"
      # << end of new code
      end
    when Array
      attr = attr.first
    else
      attr = nil
    end

    [attr&.name, value]
  end
end

class ActiveRecord::LogSubscriber
  prepend LogTruncater
end
