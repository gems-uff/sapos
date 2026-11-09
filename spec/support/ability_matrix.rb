# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

# Matriz de permissões para o golden-master de spec/models/ability_matrix_spec.rb
# (issue #742).
#
# O spec monta os usuários e o conjunto de dados; esta classe percorre papel ×
# modelo × ação e escreve, em texto estável, o que o cancancan responde:
#
# - `can?` sobre a classe e sobre cada registro rotulado do conjunto (também os
#   que só existem em memória, como a linha de autoria de um artigo ainda não
#   salvo, e os que pedem argumento extra, como a declaração);
# - `accessible_by(ability, ação)` para cada modelo, com os ids traduzidos para
#   rótulos — o id muda entre execuções, o rótulo não;
# - quantas ações em String divergem da mesma ação em Symbol, por usuário. O
#   SAPOS não chama `can?` com String (a ponte do active_scaffold aplica
#   `to_sym`), mas é a mudança do cancancan 3.7.0 que mais concede acesso, e
#   esta linha prova que ela não passa despercebida.
#
# Uma linha por usuário × modelo. A lista de ações permitidas cabe numa linha, e
# o diff do baseline aponta direto o par que mudou.
class AbilityMatrix
  STANDARD_ACTIONS = %i[index show new create edit update destroy read manage].freeze

  # Ações que o active_scaffold e as telas do SAPOS passam ao cancancan e que
  # não aparecem em regra nem em alias: sem elas na lista, só se veria o que o
  # Ability declara, e não o que a aplicação pergunta.
  APPLICATION_ACTIONS = %i[
    list row search field_search show_search export mark nested delete
    add_existing new_existing edit_associated update_column destroy_existing
    render_field duplicate undo
  ].freeze

  SYMBOL_SUBJECTS = %i[pendency landing student_enrollment].freeze

  # As ações com que a aplicação chama accessible_by: :index na listagem do
  # scaffold (beginning_of_chain), :read nas associações. As outras duas são as
  # que têm regra condicional. Só elas vão para o dump de SQL, que é diagnóstico.
  SQL_DUMP_ACTIONS = %i[index read update destroy].freeze

  EXCLUDED_NAMESPACES = /\A(ActiveRecord|ActiveStorage|ActionText|ActionMailbox|PaperTrail)::|HABTM/

  # users: { rótulo => -> { Ability } }, na ordem em que entram no baseline.
  #   É um bloco porque parte do Ability lê o banco ao ser construído
  #   (CustomVariable.professor_login_can_post_grades).
  # labels: { registro => rótulo }, persistidos ou em memória.
  # extra_args: { registro => [[args], ...] } para `can?` com argumento extra.
  def initialize(users:, labels:, extra_args: {}, sql_dump: nil)
    @users = users
    @labels = labels
    @extra_args = extra_args
    @sql_dump = sql_dump
  end

  def render
    abilities = @users.transform_values(&:call)
    actions = actions_for(abilities.values)
    lines = header(abilities.values.first, actions)
    abilities.each do |user_label, ability|
      @user_label = user_label
      lines << ""
      lines << "== #{user_label}"
      SYMBOL_SUBJECTS.each do |subject|
        lines << "#{subject}: can? #{allowed(ability, actions, subject)}"
      end
      models.each { |model| lines.concat(model_lines(ability, model, actions)) }
    end
    lines << ""
    lines << "== ações em String que divergem do Symbol (#905), por usuário"
    abilities.each do |user_label, ability|
      lines << "#{user_label}: #{string_divergences(ability, actions)}"
    end
    "#{lines.join("\n")}\n"
  end

  def models
    @models ||= begin
      Rails.application.eager_load!
      ActiveRecord::Base.descendants
        .reject { |klass| klass.abstract_class? || klass.name.nil? || klass.name.match?(EXCLUDED_NAMESPACES) }
        .push(Version)
        .uniq
        .sort_by(&:name)
    end
  end

  private
    def header(sample, actions)
      [
        "# Matriz de permissões (spec/models/ability_matrix_spec.rb, issue #742).",
        "# Gerada; não edite à mão. GOLDEN=overwrite regrava.",
        "",
        "== aliases (na ordem e com as repetições que o Ability declara)",
        *sample.aliased_actions.sort.map { |target, list| "#{target} <- #{list.join(' ')}" },
        "",
        "== ações verificadas",
        actions.join(" "),
      ]
    end

    def actions_for(abilities)
      from_rules = abilities.flat_map { |ability| ability.send(:rules).flat_map(&:actions) }
      from_aliases = abilities.first.aliased_actions.flat_map { |target, list| [target, *list] }
      (STANDARD_ACTIONS + APPLICATION_ACTIONS + from_rules + from_aliases)
        .map(&:to_sym).uniq.sort
    end

    def model_lines(ability, model, actions)
      lines = ["-- #{model.name}"]
      class_allowed = allowed(ability, actions, model)
      lines << "  classe: #{class_allowed}"
      subjects_of(model).each do |subject, label|
        variants = @extra_args.fetch(subject, [[]])
        variants.each do |args|
          name = args.empty? ? label : "#{label}(#{args.map { |arg| @labels.fetch(arg, arg) }.join(', ')})"
          result = allowed(ability, actions, subject, *args)
          lines << "  #{name}: #{result == class_allowed ? '= classe' : result}"
        end
      end
      lines << "  accessible_by: #{accessible(ability, model, actions)}"
      lines
    end

    def subjects_of(model)
      @labels.select { |record, _label| record.instance_of?(model) }
    end

    # "(tudo)", "(nada)", "tudo menos: ..." ou a lista do que é permitido —
    # o que for mais curto de ler. Erro aparece por ação, à parte.
    def allowed(ability, actions, subject, *args)
      results = actions.index_with { |action| outcome(ability, action, subject, *args) }
      list = actions.select { |action| results[action] == true }
      denied = actions - list
      errors = results.filter_map { |action, result| "#{action}=#{result}" if result.is_a?(String) }
      text =
        if denied.empty? then "(tudo)"
        elsif list.empty? then "(nada)"
        elsif denied.size < list.size then "tudo menos: #{denied.join(' ')}"
        else list.join(" ")
        end
      errors.empty? ? text : "#{text} ERRO[#{errors.join(' ')}]"
    end

    def outcome(ability, action, subject, *args)
      ability.can?(action, subject, nil, *args)
    rescue StandardError => e
      e.class.name
    end

    # Agrupa as ações pela resposta, para que o modelo caiba numa linha.
    # O grupo com mais ações sai como {demais}, para a linha caber na leitura.
    def accessible(ability, model, actions)
      groups = actions.group_by { |action| accessible_result(ability, model, action) }
      largest = groups.max_by { |_result, list| list.size }.first
      groups.map do |result, list|
        names = groups.size > 1 && result == largest ? "demais" : list.join(" ")
        names = "todas" if groups.size == 1
        "{#{names}} => #{result}"
      end.join("; ")
    end

    def accessible_result(ability, model, action)
      relation = model.accessible_by(ability, action)
      dump_sql(ability, model, action, relation)
      ids = relation.pluck(model.primary_key)
      describe_ids(model, ids)
    rescue StandardError => e
      # A mensagem do cancancan termina com o inspect do modelo, que só repete
      # as colunas.
      "ERRO #{e.class.name}: #{e.message.lines.first&.strip&.sub(/\(id: .*\z/, '')}"
    end

    def describe_ids(model, ids)
      labeled = @labels.select { |record, _| record.instance_of?(model) && record.persisted? }
      names = labeled.select { |record, _| ids.include?(record.id) }.values
      others = ids.size - names.size
      total = model.count
      parts = names.sort
      parts << "+#{others} sem rótulo" if others.positive?
      "[#{parts.join(' ')}] #{ids.size}/#{total}"
    end

    def string_divergences(ability, actions)
      pairs = models.flat_map do |model|
        actions.filter_map do |action|
          [model, action] if outcome(ability, action.to_s, model) != outcome(ability, action, model)
        end
      end
      return "nenhuma" if pairs.empty?

      "#{pairs.size} pares modelo × ação; ações: #{pairs.map(&:last).uniq.sort.join(' ')}"
    end

    def dump_sql(ability, model, action, relation)
      return if @sql_dump.nil? || !SQL_DUMP_ACTIONS.include?(action)

      @sql_dump << "#{@user_label} | #{model.name} | #{action}: #{relation.to_sql}\n"
    end
end
