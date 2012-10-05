class AddTemplates < ActiveRecord::Migration
  def self.up
    add_column :requests, :response_body, :text
    add_column :requests, :response_params, :text
  end

  def self.down
    remove_column :requests, :response_body
    remove_column :requests, :response_params
  end
end
