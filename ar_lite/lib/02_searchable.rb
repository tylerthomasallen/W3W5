require_relative 'db_connection'
require_relative '01_sql_object'

# Let's write a module named Searchable which will add the ability to search using ::where. By using extend, we can mix in Searchable to our SQLObject class, adding all the module methods as class methods.
#
# So let's write Searchable#where(params). Here's an example:
#
# haskell_cats = Cat.where(:name => "Haskell", :color => "calico")
# # SELECT
# #   *
# # FROM
# #   cats
# # WHERE
# #   name = ? AND color = ?
# I used a local variable where_line where I mapped the keys of the params to "#{key} = ?" and joined with AND.
#
# To fill in the question marks, I used the values of the params object.
#


module Searchable
  def where(params)
    where_line = params.keys.map { |key| "#{key} = ?"}.join(' AND ')
    results = DBConnection.execute(<<-SQL, *params.values)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{where_line}
    SQL

    parse_all(results)
  end
end

class SQLObject
  extend Searchable
end
