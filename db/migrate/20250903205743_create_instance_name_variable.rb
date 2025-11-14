class CreateInstanceNameVariable < ActiveRecord::Migration[7.0]
  def up
    CustomVariable.where(
      variable: "instance_name"
    ).first || CustomVariable.create(
      description: "Nome do programa",
      variable: "instance_name",
      value: nil
    )
  end
end
