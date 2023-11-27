module RecordSelectHelper
  # Adds a RecordSelect-based form field. The field submits the record's id using a hidden input.
  #
  # *Arguments*
  # +name+:: the input name that will be used to submit the selected record's id.
  # +current+:: the currently selected object. provide a new record if there're none currently selected and you have not passed the optional :controller argument.
  #
  # *Options*
  # +controller+::  The controller configured to provide the result set. Optional if you have standard resource controllers (e.g. UsersController for the User model), in which case the controller will be inferred from the class of +current+ (the second argument)
  # +params+::      A hash of extra URL parameters
  # +id+::          The id to use for the input. Defaults based on the input's name.
  # +field_name+::  The name to use for the text input. Defaults to '', so field is not submitted.
  # +rs+::          Options for RecordSelect constructor
  def record_select_field(name, current, options = {})
    options[:controller] ||= current.class.to_s.pluralize.underscore
    options[:params] ||= {}
    options[:id] ||= name.gsub(/[\[\]]/, '_')
    options[:class] ||= ''
    options[:class] << ' recordselect'

    controller = assert_controller_responds(options.delete(:controller))
    params = options.delete(:params)
    record_select_options = {id: record_select_id(controller.controller_path)}
    record_select_options[:field_name] = options.delete(:field_name) if options[:field_name]
    if current and not current.new_record?
      record_select_options[:id] = current.id
      record_select_options[:label] = label_for_field(current, controller)
    end
    record_select_options.merge! options[:rs] if options[:rs]

    html = text_field_tag(name, nil, options.merge(:autocomplete => 'off', :onfocus => "this.focused=true", :onblur => "this.focused=false"))
    url = url_for({:action => :browse, :controller => "/#{controller.controller_path}"}.merge(params))
    html << javascript_tag("new RecordSelect.Single(#{options[:id].to_json}, #{url.to_json}, #{record_select_options.to_json});")

    return html
  end
end