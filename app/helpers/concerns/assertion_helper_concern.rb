# app/helpers/concerns/assertion_helper_concern.rb
module AssertionHelperConcern
  def get_query_results(assertion, args)
    assertion.query.execute(args)
  end
end