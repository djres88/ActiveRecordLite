require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    @calculated ||= false
    return @columns if @calculated == true
    data = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        "#{self.table_name}";
    SQL
    @calculated = true
    @columns = data.first
    @columns.map!(&:to_sym)
    # ...
  end

  def self.finalize!
    columns.each do |header|
      #getter
      define_method("#{header}") do
        attributes[header]
      end

      #setter
      define_method("#{header}=") do |store_stuff|
        attributes[header] = store_stuff
      end
    end

  end

  def self.table_name=(table_name)
    # ...
    @table_name = table_name
  end

  def self.table_name
    # instance_variable_get("@#{table_name}")
    @table_name ||= "#{self}".downcase + "s"

    # ...
  end

  def self.all
    data = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        '#{self.table_name}'
    SQL
    # p data
    self.parse_all(data)
  end

  def self.parse_all(results)
    results.map do |result|
      self.new(result)
    end
  end

  def self.find(id)
    object = DBConnection.execute(<<-SQL, id)
    SELECT
      *
    FROM
      '#{self.table_name}'
    WHERE
      ? = '#{self.table_name}'.id
    SQL

    (object.first.nil?) ? nil : self.new(object.first)
  end

  def initialize(params = {})
    # ...
    valid_column_ids = self.class.columns

    params.each do |attr_name, value|
      attr_name = attr_name.to_sym

      unless valid_column_ids.include?(attr_name)
        raise "unknown attribute \'#{attr_name}\'"
      end

      self.send("#{attr_name}=", value)
    end
  end

  def attributes
    @attributes ||= {}
    # ...
  end

  def attribute_values
    self.class.columns.map { |column| send(column) }
  end

  def insert
    col_names = self.class.columns
    question_marks = (["?"] * col_names.length).join(', ')
    col_names = col_names.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values)
      INSERT INTO
        "#{self.class.table_name}" (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
    # ...
  end

  def update
    set_line = self.class.columns.map { |attr_name| "#{attr_name} = ?" }.join(', ')

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        "#{self.class.table_name}"
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
    # ...
  end

  def save
    if self.id.nil?
      self.insert
    else
      self.update
    end
  end
end
