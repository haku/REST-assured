class AddTemplates < ActiveRecord::Migration
  def self.up
    add_column :requests, :response_body, :text
    add_column :requests, :response_params, :text
    add_column :doubles, :request_count, :integer
    add_column :doubles, :template_type, :text
  end

  def self.down
    remove_column :requests, :response_body
    remove_column :requests, :response_params
    remove_column :doubles, :request_count
    remove_column :doubles, :template_type
  end
end
