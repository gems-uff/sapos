# frozen_string_literal: true

module AdmissionReportFixedGroups
  def configured_groups(config)
    config[:groups].reject { |group| group.group.fixed? }
  end

  def fixed_section?(column, config)
    fixed = config[:groups].select { |group| group.group.fixed? }.flat_map(&:sections)
    fixed.any? { |section| section.equal?(column[:section]) }
  end
end
