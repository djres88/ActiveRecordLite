require 'byebug'
require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    args = params.values
    where_line = params.keys.map! { |key| "#{key} = ?"}.join(" AND ")

    # byebug

    data = DBConnection.execute(<<-SQL, *args)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    n = data.map! { |object| self.new(object) }
    p n
  end


end

class SQLObject
  # Mixin Searchable here...
  extend Searchable
end
