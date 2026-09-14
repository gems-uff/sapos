# Copyright (c) Universidade Federal Fluminense (UFF).
# This file is part of SAPOS. Please, consult the license terms in the LICENSE file.

# frozen_string_literal: true

require "rails_helper"

# Campo preenchido (#681): o texto que cada tipo de campo apresenta nos
# relatórios, a cópia de valor para o aluno com registro do que mudou, e a
# conversão de valor por tipo que as condições e o ranking usam.
RSpec.describe Admissions::FilledFormField, "texto e cópia para o aluno", type: :model do
  before(:each) do
    @template = create_admission_template("Inscrição", {
      "texto" => Admissions::FormField::STRING,
      "opcao" => { field_type: Admissions::FormField::SELECT, configuration: { "values" => ["Sim", "Não"] } },
      "marcacoes" => { field_type: Admissions::FormField::COLLECTION_CHECKBOX,
                       configuration: { "values" => ["Alfa", "Beta"], "default_values" => ["Gama"] } },
      "anexo" => Admissions::FormField::FILE,
      "cidade" => Admissions::FormField::CITY,
      "endereco" => Admissions::FormField::RESIDENCY,
      "foto" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "photo" } },
      "nascimento" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "special_birth_city" } },
      "moradia" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "special_address" } },
      "formacao" => { field_type: Admissions::FormField::STUDENT_FIELD,
                      configuration: { "field" => "special_majors", "values" => ["Graduação"], "statuses" => ["Completo"] } },
      "cpf" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "cpf" } },
      "aniversario" => { field_type: Admissions::FormField::STUDENT_FIELD, configuration: { "field" => "birthdate" } },
    })
    @process = create_closed_admission_process(@template, simple_url: "filled-field-spec")
    @application = create_application(@process)
    @filled_form = @application.filled_form
  end

  def field(name, **attrs)
    form_field = @template.fields.find_by!(name: name)
    Admissions::FilledFormField.new({ filled_form: @filled_form, form_field: form_field }.merge(attrs))
  end

  def png
    Rack::Test::UploadedFile.new(Rails.root.join("spec/fixtures/user.png"), "image/png")
  end

  # A URL de download lê o host de RAILS_RELATIVE_URL_ROOT, que a suíte não
  # define; sem ele o url_helper recusa montar a URL.
  def with_download_host
    old = ENV["RAILS_RELATIVE_URL_ROOT"]
    ENV["RAILS_RELATIVE_URL_ROOT"] = "http://sapos.test"
    yield
  ensure
    ENV["RAILS_RELATIVE_URL_ROOT"] = old
  end

  describe "#to_text" do
    it "devolve o texto em branco sem campo ou sem valor" do
      expect(Admissions::FilledFormField.new.to_text).to eq("-")
      expect(field("texto").to_text(blank: "")).to eq("")
      expect(field("texto", value: "abc").to_text).to eq("abc")
    end

    it "traduz a opção do select pelo rótulo" do
      expect(field("opcao", value: "Sim").to_text).to eq("Sim")
      expect(field("opcao").to_text).to eq("-")
    end

    it "lista as marcações pelos rótulos, inclusive as padrão" do
      expect(field("marcacoes", list: ["Alfa", "Gama", ""]).to_text).to eq("Alfa, Gama")
      expect(field("marcacoes", list: []).to_text).to eq("-")
    end

    it "monta a URL de download do arquivo" do
      filled = field("anexo", file: png)
      filled.save!
      with_download_host do
        expect(filled.to_text).to eq("http://sapos.test/files/#{filled.file.medium_hash}")
      end
      expect(field("anexo").to_text).to eq("-")
    end

    it "separa cidade, estado e país por vírgula, completando o que falta" do
      expect(field("cidade", value: "Niterói <$> RJ <$> Brasil").to_text).to eq("Niterói, RJ, Brasil")
      expect(field("cidade", value: "Niterói").to_text).to eq("Niterói, , ")
      expect(field("cidade").to_text).to eq("-")
    end

    it "separa as partes do endereço" do
      expect(field("endereco", value: "Rua A <$> 10").to_text).to eq("Rua A, 10")
      expect(field("endereco").to_text).to eq("-")
    end

    it "delega os campos de aluno ao tipo equivalente" do
      expect(field("nascimento", value: "Rio <$> RJ <$> Brasil").to_text).to eq("Rio, RJ, Brasil")
      expect(field("moradia", value: "Rua B <$> 2").to_text).to eq("Rua B, 2")
      expect(field("cpf", value: "123").to_text).to eq("123")
      photo = field("foto", file: png)
      photo.save!
      with_download_host { expect(photo.to_text).to include(photo.file.medium_hash) }
    end

    it "descreve as formações com rótulos de nível e situação" do
      filled = field("formacao")
      filled.scholarities.build(level: "Graduação", status: "Completo", institution: "UFF", course: "Computação",
        start_date: Date.new(2015, 3, 1), end_date: Date.new(2019, 12, 1))
      expect(filled.to_text).to eq("Graduação - Completo - UFF - Computação (01/03/2015 - 01/12/2019)")
      expect(field("formacao").to_text).to eq("-")
    end

    it "usa o formatador customizado do tipo quando dado" do
      custom = { Admissions::FormField::FILE => ->(filled, form_field) { "arquivo de #{form_field.name}" } }
      expect(field("anexo", file: png).to_text(custom: custom)).to eq("arquivo de anexo")
    end
  end

  describe "#to_label" do
    it "mostra nome e valor, arquivo ou lista" do
      expect(field("texto", value: "abc").to_label).to eq("texto: abc")
      expect(field("marcacoes", list: ["Alfa"]).to_label).to eq('marcacoes: ["Alfa"]')
      expect(field("texto").to_label).to eq("texto: -")
      expect(Admissions::FilledFormField.new.to_label).to eq("-")
    end
  end

  describe "#simple_value" do
    it "prefere o arquivo, depois a lista, depois o valor" do
      expect(field("anexo", file: png).simple_value).to be_a(FormFileUploader)
      expect(field("marcacoes", list: ["Alfa"]).simple_value).to eq(["Alfa"])
      expect(field("texto", value: "x").simple_value).to eq("x")
    end
  end

  describe "#set_model_field" do
    it "grava o valor e anota a alteração com o valor anterior" do
      student = Student.new(name: "Antiga")
      log = []
      field("texto", value: "Nova").set_model_field(log, student, "name")
      expect(student.name).to eq("Nova")
      expect(log).to eq(["#{Student.record_i18n_attr("name")} alterado. Valor anterior: Antiga"])
    end

    it "não anota quando o valor é o mesmo nem grava valor em branco" do
      student = Student.new(name: "Igual")
      log = []
      field("texto", value: "Igual").set_model_field(log, student, "name")
      field("texto", value: "").set_model_field(log, student, "obs")
      expect(log).to be_empty
      expect(student.obs).to be_nil
    end

    it "omite o valor anterior quando ele é grande demais para a observação" do
      student = Student.new(obs: "x" * 5000)
      log = []
      field("texto", value: "curto").set_model_field(log, student, "obs")
      expect(log).to eq(["#{Student.record_i18n_attr("obs")} alterado."])
    end
  end

  describe "#set_model_place_field" do
    before(:each) do
      @country = FactoryBot.create(:country, name: "Brasil")
      @state = FactoryBot.create(:state, name: "Rio de Janeiro", code: "RJ", country: @country)
      @city = FactoryBot.create(:city, name: "Niterói", state: @state)
    end

    it "acha o lugar pelo nome e o grava, anotando a troca" do
      student = Student.new(city: FactoryBot.create(:city, name: "Outra", state: @state))
      log = []
      field("cidade").set_model_place_field(
        City, nil, log, student, "city", "não achou", city: "Niterói", state: "RJ", country: "Brasil"
      )
      expect(student.city).to eq(@city)
      expect(log.first).to start_with("#{Student.record_i18n_attr("city")} alterado. Valor anterior: Outra")
    end

    it "usa o lugar já dado em vez de procurar" do
      student = Student.new
      field("cidade").set_model_place_field(State, @state, [], student, "birth_state", "não achou", state: "ZZ")
      expect(student.birth_state).to eq(@state)
    end

    it "anota quando não acha" do
      log = []
      student = Student.new
      field("cidade").set_model_place_field(Country, nil, log, student, "birth_country", "País não achado", country: "Atlântida")
      expect(student.birth_country).to be_nil
      expect(log).to eq(["País não achado"])
    end
  end

  describe ".convert_value" do
    it "converte por tipo e devolve nil quando não consegue" do
      expect(Admissions::FilledFormField.convert_value("8.5", "number")).to eq(8.5)
      expect(Admissions::FilledFormField.convert_value(nil, "number")).to eq(0.0)
      expect(Admissions::FilledFormField.convert_value(8, "string")).to eq("8")
      expect(Admissions::FilledFormField.convert_value("15/03/2020", "date")).to eq(Date.new(2020, 3, 15))
      expect(Admissions::FilledFormField.convert_value("2020-03-15", "date")).to be_nil
      expect(Admissions::FilledFormField.convert_value(["a"], "list")).to eq(["a"])
    end

    it "get_type vem do campo de formulário, inclusive para datas de aluno" do
      expect(field("aniversario").get_type).to eq("date")
      expect(field("cpf").get_type).to eq("string")
      expect(field("texto").get_type).to eq("string")
    end
  end

  describe "validação de arquivo" do
    it "exige arquivo quando o campo é obrigatório e restringe a extensão" do
      form_field = @template.fields.find_by!(name: "anexo")
      form_field.update!(configuration: JSON.dump({ "required" => true, "values" => [".pdf"] }))
      filled = field("anexo")
      expect(filled).not_to be_valid
      expect(filled.errors[:file].join).to include(I18n.t("errors.messages.blank"))

      with_png = field("anexo", file: png)
      expect(with_png).not_to be_valid
      expect(with_png.errors[:file].join).to include(".pdf")
    end

    it "recusa arquivo e valor no mesmo campo" do
      filled = field("anexo", file: png, value: "x")
      expect(filled).not_to be_valid
    end
  end
end
