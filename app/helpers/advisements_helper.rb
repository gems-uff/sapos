module AdvisementsHelper
  def active_search_column(record,options)
    select(record, :active, [["Ativas","active"],["Inativas","not_active"],["Todas","all"]], options, options)
  end
  
  def level_search_column(record,options)
    levels = Level.all.map { |level| [level.name,level.id]}
    levels.push(["Todos",nil])
    select(record, :level, levels, options,options)
  end
end