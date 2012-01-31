module AdvisementsHelper
  def active_search_column(record,options)
    checked_default = {:checked => true}
    check_box(record, :active, options.merge(checked_default), true, false) 
  end
end