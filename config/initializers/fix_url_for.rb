# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# Reason: In a namespaced controller (e.g., Admissions::), url_for considers
# that "controller:" parameters refer to relative paths, unless they start with a '/'.
# So, when a namespaced view/template tries to create a link to a view outside (e.g., Student),
# url_for raises an exception.
# To make matter worse, Active Scaffold uses ActionController.controller_path
# in many situations and pass the result to url_for to handle the dynamic nature of the tool.
# This method does return the absolute path of the controllers, but it does not
# include the '/' in the beginning.
# We cannot safely override all usages of controller_path in ActiveScafold to fix it,
# so, this monkey patch overrides Rails url_for to make it try it find the path again
# using the absolute controller definition if it fails to find initially

# Possible side effect:
#   If a model appears in different namespaces, the fix may not find the correct url

module RoutingUrlForExtensions
  def url_for(options = nil)
    super
  rescue ActionController::UrlGenerationError
    if options.present? && options[:controller].present?
      super(options.merge(controller: "/#{options[:controller]}"))
    else
      raise
    end
  end
end

module ActionView
  module RoutingUrlFor
    prepend RoutingUrlForExtensions
  end
end
