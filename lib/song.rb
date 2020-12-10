require_relative "../config/environment.rb"
require 'active_support/inflector'

class Song


  def self.table_name
    self.to_s.downcase.pluralize   #=> songs
  end

  def self.column_names
    DB[:conn].results_as_hash = true

    sql = "pragma table_info('#{table_name}')"

    table_info = DB[:conn].execute(sql) #=> will return an array of hashes
    column_names = []
    table_info.each do |row|
      column_names << row["name"]   #=> iterates and pushes each column name
    end
    column_names.compact #=> returns column names and removes nil
  end

  self.column_names.each do |col_name| #=> creates attr_accessors for each column name
    attr_accessor col_name.to_sym # this instantly runs when the class is run
  end

  def initialize(options={}) #expect a hash when a new instance of class is created
    options.each do |property, value|
      self.send("#{property}=", value) #can assign values to previously created class accessor
    end
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert #gets table name from class method for use in save method
    self.class.table_name
  end

  def values_for_insert #gets values using column names which = attr_reader names to use in save method
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def col_names_for_insert #gets column names from class method for use in save method
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"
    DB[:conn].execute(sql)
  end

end



