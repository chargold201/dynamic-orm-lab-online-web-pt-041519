require_relative "../config/environment.rb"
require 'active_support/inflector'

class InteractiveRecord

    def initialize(options={})
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end
    
    def self.table_name
        self.to_s.downcase.pluralize
    end

    def self.column_names
        DB[:conn].results_as_hash = true

        sql = <<-SQL
            PRAGMA table_info('#{self.table_name}')
        SQL
        table_data = DB[:conn].execute(sql)

        column_names = []
        table_data.each do |row|
            column_names << row['name']
        end
        column_names
    end

    def table_name_for_insert
        self.class.table_name
    end

    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
        values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
        DB[:conn].execute(sql, name)
    end

    def self.find_by(attr_hash)
        sql = "SELECT * FROM #{self.table_name} WHERE #{attr_hash.keys[0]} = ?"
        DB[:conn].execute(sql, attr_hash[attr_hash.keys[0]])
    end
end