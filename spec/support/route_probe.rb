# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Percorre as rotas da aplicação como um usuário percorreria: um request por
# rota, com o verbo dela, e a resposta reduzida a um desfecho estável (issue
# #742). É a camada que a matriz do Ability não alcança — ela pergunta ao
# Ability; aqui se prova que o controller pergunta.
#
# Cada request roda num savepoint desfeito em seguida: um DELETE não some com o
# registro que o request seguinte usa.
module RouteProbe
  # Rotas de outras engines ou de recurso que o SAPOS não usa (Active Storage
  # não tem tabelas: os uploads são CarrierWave).
  FOREIGN_CONTROLLERS = %r{\A(rails/|active_storage/|action_mailbox/|turbo/)}

  # Parâmetros obrigatórios além do :id, quando o spec não dá um valor real.
  PATH_PARAMS = {
    signature_type: "qr_code",
    year: "2021",
    semester: "1",
  }.freeze

  # Rotas que dispensam autorização de propósito, abertas a quem não tem
  # permissão: controller#action (ou controller#* para o controller inteiro)
  # => motivo. O Ability não responde por elas.
  ROTAS_ABERTAS = {
    "application#root" => "redireciona à página inicial do papel",
    "landing#index" => "todo usuário autenticado lê a página inicial (Ability)",
    "credits#show" => "créditos do sistema",
    "users/sessions#*" => "Devise: entrar e sair",
    "users/passwords#*" => "Devise: recuperar a senha",
    "users/confirmations#*" => "Devise: confirmar o e-mail",
    "users/unlocks#*" => "Devise: desbloquear a conta",
    "users/user_invitations#*" => "Devise: aceitar convite",
    "users/registrations#*" => "Devise: o perfil do próprio usuário",
    "user_roles#change_role" => "troca o papel atual entre os papéis do próprio usuário; o controller confere o vínculo",
    "admissions/admissions#*" => "processo seletivo público (ProcessBaseController desliga a autorização)",
    "admissions/apply#*" => "processo seletivo público (ProcessBaseController desliga a autorização)",
    "admissions/letters#*" => "carta de recomendação, pública (ProcessBaseController desliga a autorização)",
    "admissions/email_changes#*" => "confirmação da troca de e-mail da inscrição, pública; o link é a credencial",
    "admissions/form_autocompletes#*" => "autocomplete do formulário público de inscrição",
    "files#download" => "download pelo hash, que funciona como credencial",
    "reports#download_by_identifier" => "validação pública do documento pelo identificador do QR",
  }.freeze

  def self.aberta?(route)
    ROTAS_ABERTAS.key?("#{route.controller}##{route.action}") || ROTAS_ABERTAS.key?("#{route.controller}#*")
  end

  Route = Struct.new(:verb, :path_spec, :controller, :action, :journey, keyword_init: true) do
    def to_s
      "#{verb} #{path_spec.sub('(.:format)', '')} #{controller}##{action}"
    end
  end

  def self.routes
    Rails.application.routes.routes.filter_map do |journey|
      controller = journey.defaults[:controller]
      action = journey.defaults[:action]
      next if controller.nil? || action.nil? || controller.match?(FOREIGN_CONTROLLERS)

      Route.new(
        verb: journey.verb.split("|").first.presence || "GET",
        path_spec: journey.path.spec.to_s,
        controller: controller, action: action, journey: journey
      )
    end.uniq { |route| [route.verb, route.path_spec, route.controller, route.action] }
  end

  # O modelo do scaffold do controller, quando há um.
  def self.model_for(controller)
    klass = "#{controller.camelize}Controller".safe_constantize
    return unless klass.respond_to?(:active_scaffold_config)

    klass.active_scaffold_config&.model
  rescue StandardError
    nil
  end

  def route_path(route, id:, extra: {})
    params = PATH_PARAMS.merge(extra).merge(id: id)
    route.journey.format(params.slice(*route.journey.required_parts))
  end

  # Endereço de documentação (RFC 5737). O better_errors, que está no grupo de
  # teste, só intercepta request de IP local; fora dele, a exceção sobe inteira
  # até aqui (show_exceptions = :none), com classe e mensagem. Sem isso, uma
  # recusa do cancancan e um defeito saem iguais, como página de erro 500.
  REMOTE_ADDR = "203.0.113.7"

  # Faz o request e devolve o desfecho em texto.
  def probe(route, path, params: {}, xhr: false)
    outcome = nil
    ActiveRecord::Base.transaction(requires_new: true) do
      outcome = probe_outcome(route) do
        process(route.verb.downcase.to_sym, path, params: params, xhr: xhr, env: { "REMOTE_ADDR" => REMOTE_ADDR })
      end
      raise ActiveRecord::Rollback
    end
    outcome
  end

  def probe_outcome(route)
    yield
    return "#{response.status} #{redirect_target}" if response.redirect?

    response.status.to_s
  rescue StandardError => e
    exception_outcome(e, route)
  end

  def exception_outcome(exception, route)
    # A view embrulha o que levantou dentro dela; o que importa é a causa.
    exception = exception.cause if exception.is_a?(ActionView::Template::Error) && exception.cause
    case exception
    when CanCan::AccessDenied then "negado"
    when ActiveScaffold::RecordNotAllowed, ActiveScaffold::ActionNotAllowed then "negado (active_scaffold)"
    when ActiveRecord::RecordNotFound then "não encontrado"
    when AbstractController::ActionNotFound then "ação inexistente"
    when ActionController::RoutingError then "não encontrado (rota)"
    else
      return "ação desabilitada" if exception.is_a?(ArgumentError) && exception.message.include?("is not enabled for")
      return "ação sem método" if exception.is_a?(ActionController::UnknownFormat) && !action_method?(route)

      "erro #{exception.class.name}"
    end
  end

  # Rota que aponta para ação que o controller não define: o Rails procura um
  # template implícito, não acha, e o request não chega a fazer nada.
  def action_method?(route)
    klass = "#{route.controller.camelize}Controller".safe_constantize
    klass.nil? || klass.action_methods.include?(route.action)
  end

  # Só o caminho do redirecionamento, sem host nem query, e com o id trocado por
  # :id: a query carrega mensagem e o id muda entre execuções, e nenhum dos dois
  # diz algo sobre autorização.
  def redirect_target
    location = response.location.to_s
    URI.parse(location).path.gsub(%r{/\d+(?=/|\z)}, "/:id")
  rescue URI::InvalidURIError
    location
  end
end
