# app/helpers/concerns/assertion_helper_concern.rb
module AssertionHelperConcern
  def get_query_results(assertions)
    assertions.query.execute
  end
end