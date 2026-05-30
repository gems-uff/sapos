require 'ripper'

class ConvertConsolidateCodeFieldsFromRubyToLiquid < ActiveRecord::Migration[7.0]
  MEDIAN_PATTERN_RUBY = /
    (?<grades>[_a-zA-Z][_a-zA-Z0-9]*?) \s* = \s* committees\.map\{ \s* \|\s*(?<x>[_a-zA-Z][_a-zA-Z0-9]*?)\s*\| \s* \k<x> \s* \[['"](?<field>.*?)['"]\].to_f \s* \} \s*
    (?<sorted>[_a-zA-Z][_a-zA-Z0-9]*?) \s* = \s* [_a-zA-Z][_a-zA-Z0-9]*?\.sort \s*
    (?<length>[_a-zA-Z][_a-zA-Z0-9]*?) \s* = \s* [_a-zA-Z][_a-zA-Z0-9]*?\.length \s*
    \(\k<sorted>\[\s*\(\s*\k<length> \s* - \s* 1 \s*\) \s* \/ \s* 2 \s*\] \s* \+ \s* \k<sorted>\[\s* \k<length> \s* \/ \s* 2 \s*\]\s*\) \s* \/ \s* 2.0
    /mx
  MEDIAN_PATTERN_LIQUID = /
    \{\{-? \s* committees \s* \| \s* median: \s* ['"](?<field>.*?)['"] \s* -?\}\}
    /mx
  AVG_PATTERN_RUBY = /
    (?<grades>[_a-zA-Z][_a-zA-Z0-9]*?) \s* = \s* committees\.map\{ \s* \|\s*(?<x>[_a-zA-Z][_a-zA-Z0-9]*?)\s*\| \s* \k<x> \s* \[['"](?<field>.*?)['"]\].to_f \s* \} \s*
    \k<grades>\.sum \s* \/ \s* \k<grades>\.size
    /mx
  AVG_PATTERN_LIQUID = /
    \{\{-? \s* committees \s* \| \s* avg: \s* ['"](?<field>.*?)['"] \s* -?\}\}
    /mx

  FIELD_AVG_PATTERN_LIQUID = /
    (?<assignments>(\{%-? \s* assign \s* v\d+ \s* = \s* fields\[ \s* ['"].*?['"] \s* \] \s* (\| \s* times: \s* \d.*? \s*)? -?%\} \s*)+)
    \{%-? \s* assign \s* sum \s* = \s* v1 \s* (\| \s* plus: \s* v\d+ \s*)* -?%\} \s*
    \{\{-? \s* sum \s* \| \s* divided_by: \s* (?<div>.*?) \s* -?\}\}
    /mx
    
  ASSIGNMENT_PATTERN_LIQUID = /
    \{%-? \s* assign \s* v(?<var>\d+) \s* = \s* fields\[ \s* ['"](?<field>.*?)['"] \s* \] \s* (\| \s* times: \s* (?<mult>\d.*?) \s*)? -?%\} \s*
    /mx
  
  def extract_weight_ruby(sexp, mult)
    v1 = extract_sum(sexp)
    case v1
    in [{field:}]
      return [{field:, mult:}]
    else
      return false
    end
  end

  def extract_sum_ruby(sexp)
    case sexp
    in [:aref,
      [:vcall, [:@ident, "fields", _]],
      [:args_add_block,
       [[:string_literal, [:string_content, [:@tstring_content, String => field, _]]]],
       false]
    ]
      return [{field:}]
    in [:binary, v1, :+, v2]
      return extract_sum_ruby(v1) + extract_sum_ruby(v2)
    in [:binary, [_, String => mult, _], :*, v1]
      return extract_weight_ruby(v1, mult)
    in [:binary, v1, :*, [_, String => mult, _]]
      return extract_weight_ruby(v1, mult)
    else
      false
    end
  rescue
    false
  end

  def convert_ruby_to_liquid(code)
    if code =~ MEDIAN_PATTERN_RUBY
      return "{{- committees | median: '#{$~[:field]}' -}}"
    elsif code =~ AVG_PATTERN_RUBY
      return "{{- committees | avg: '#{$~[:field]}' -}}"
    else
      # Match (fields['a'] + fields['b'])/2
      case Ripper.sexp(code)
      in [:program,
        [[:binary,
          [:paren,
           [val]],
          :/,
          [_, div, _]]]]
        fields = extract_sum_ruby(val)
        if fields
          result = []
          names = []
          fields.each_with_index do |field, index|
            names << ["v#{index + 1}"]
            mult_str = ""
            mult_str = " | times: #{field[:mult]}" if field.include?(:mult)
            result << "{%- assign v#{index + 1} = fields['#{field[:field]}']#{mult_str} -%}"
          end
          result << "{%- assign sum = #{names.join(" | plus: ")} -%}"
          result << "{{- sum | divided_by: #{div.to_f} -}}"
          return result.join("\n")
        end
      else
        return false
      end
    end
    return false
  end

  def convert_liquid_to_ruby(code)
    if code =~ MEDIAN_PATTERN_LIQUID
      return <<~CODE.strip
        grades = committees.map{ |x| x["#{$~[:field]}"].to_f }
        sorted = grades.sort
        length = grades.length
        (sorted[(length - 1) / 2] + sorted[length / 2]) / 2.0
      CODE
    elsif code =~ AVG_PATTERN_LIQUID
      return <<~CODE.strip
        grades = committees.map{ |x| x["#{$~[:field]}"].to_f }
        grades.sum / grades.size
      CODE
    elsif code =~ FIELD_AVG_PATTERN_LIQUID
      div = $~[:div]
      fields = []
      $~[:assignments].scan(ASSIGNMENT_PATTERN_LIQUID) do |group|
        mult = group[2] ? " * #{group[2]}" : ""
        fields << "fields[\"#{group[1]}\"]#{mult}"
      end
      if fields
        return "(#{fields.join(' + ')}) / #{div}"
      end
    end
    return false
  end
  
  def up
    Admissions::FormField.where(field_type: Admissions::FormField::CODE).each do |form_field|
      config = JSON.parse(form_field.configuration)
      next if config["template_type"] != "Ruby"
      converted = convert_ruby_to_liquid(config["code"])
      puts "#{form_field.name} (#{form_field.form_template.name})"
      if converted
        config["code"] = converted
        config["template_type"] = "Liquid"
        form_field.configuration = JSON.dump(config)
        form_field.save!
        puts '..Converted'
      else
        puts '..Incomplete conversion. Kept Ruby'
      end
    end
  end

  def down
    Admissions::FormField.disable_erb_validation! do
      Admissions::FormField.where(field_type: Admissions::FormField::CODE).each do |form_field|
        config = JSON.parse(form_field.configuration)
        next if config["template_type"] != "Liquid"
        converted = convert_liquid_to_ruby(config["code"])
        puts "#{form_field.name} (#{form_field.form_template.name})"
        if converted
          config["code"] = converted
          config["template_type"] = "Ruby"
          form_field.configuration = JSON.dump(config)
          form_field.save!
          puts '..Converted'
        else
          puts '..Incomplete conversion. Kept Liquid'
        end
      end
    end
  end

end
