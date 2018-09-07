require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    if @columns
      @columns
    else
      result = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{table_name}"
      SQL
      @columns = result.first.map(&:to_sym)
      @columns
    end
  end

  def self.finalize!
    columns.each do |col|

      define_method(col) do
        @attributes ||= {}
        @attributes[col]
      end

      define_method("#{col}=") do |value|
        @attributes ||= {}
        @attributes[col] = value
      end

    end
  end

  def self.table_name=(table_name)
    @table = table_name
  end

  def self.table_name
    @table || "#{self.to_s.downcase}s"
  end

  def self.all
    table = table_name
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{table}"
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    result = []
    results.each do |hash|
      result << new(hash)
    end
    result
  end

  def self.find(id)
    table = table_name
    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        "#{table}"
      WHERE
        id = "#{id}"
    SQL

    return nil if result.empty?
    new(result.first)
  end

  def initialize(params = {})
    self.class.finalize!
    params.each do |k, v|
      k = k.to_sym
      raise "unknown attribute '#{k}'" unless self.class.columns.include?(k)
      send("#{k}=", v)
    end
  end

  def attributes
    @attributes = {} if @attributes.nil?
    @attributes
  end

  def attribute_values
    vals = []
    self.class.columns.each do |key|
      vals << attributes[key]
    end
    vals
  end

  def insert
    table = self.class.table_name
    cols = self.class.columns.drop(1)
    col_names = cols.map(&:to_s).join(', ')
    vals = attribute_values.drop(1)
    question_marks = (['?'] * cols.count).join(', ')
    # debugger
    DBConnection.execute(<<-SQL, *vals)
    INSERT INTO
      #{table} (#{col_names})
    VALUES
      (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    set_line = self.class.columns.map { |att| "#{att} = ?"}.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values, id)
    UPDATE
      "#{self.class.table_name}"
    SET
      #{set_line}
    WHERE
      #{self.class.table_name}.id = ?
    SQL
  end

  def save
    id.nil? ? insert : update
  end
end
