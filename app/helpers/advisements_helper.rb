module AdvisementsHelper
  def active_search_column(record,options)
    select(record, :active, [["Ativas","active"],["Inativas","not_active"],["Todas","all"]], options, options)
  end
end