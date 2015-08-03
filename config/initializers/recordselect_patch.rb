require 'active_record/connection_adapters/abstract_mysql_adapter'

module ActiveRecord
  module ConnectionAdapters
    class AbstractMysqlAdapter < AbstractAdapter
      class Column < ConnectionAdapters::Column # :nodoc:
        def type_cast(val)
          self.type_cast_from_user(val)
        end
      end
    end

    class AbstractAdapter
      class Column < ConnectionAdapters::Column # :nodoc:
        def type_cast(val)
          self.type_cast_from_user(val)
        end
      end
    end
  end
end
