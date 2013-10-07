module VersionsHelper
	def whodunnit_column(record, column)
		name = record.object[/:\s\w+/][2..-1] if not record.object.nil?
		name#link_to(h(name), :action => :show, :controller => 'users', :id => record.whodunnit)
	end
end