# app/helpers/concerns/assertion_helper_concern.rb
module AssertionHelperConcern
  def get_avulso_results(assertions)
    assertions.query.execute
  end
end