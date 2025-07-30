# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

CourseType.create([
  { name: "Seminário", has_score: false, schedulable: true, show_class_name: false, allow_multiple_classes: false, on_demand: false },
  { name: "Pesquisa de Dissertação e Tese", has_score: false, schedulable: true, show_class_name: false, allow_multiple_classes: true, on_demand: true },
  { name: "Tópicos Avançados", has_score: true, schedulable: true, show_class_name: true, allow_multiple_classes: true, on_demand: false },
  { name: "Obrigatória de Curso", has_score: true, schedulable: true, show_class_name: false, allow_multiple_classes: false, on_demand: false },
  { name: "Obrigatória de Linha de Pesquisa", has_score: true, schedulable: true, show_class_name: false, allow_multiple_classes: false, on_demand: false },
  { name: "Optativa", has_score: true, schedulable: true, show_class_name: false, allow_multiple_classes: false, on_demand: false },
  { name: "Estágio em Docência", has_score: true, schedulable: true, show_class_name: false, allow_multiple_classes: true, on_demand: false },
  { name: "Estudo Orientado", has_score: true, schedulable: true, show_class_name: false, allow_multiple_classes: false, on_demand: true },
  { name: "Defesa de Dissertação e Tese", has_score: false, schedulable: false, show_class_name: false, allow_multiple_classes: false, on_demand: false },
])
