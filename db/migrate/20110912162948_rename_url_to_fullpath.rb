class RenameUrlToFullpath < ActiveRecord::Migration
  def self.up
    rename_column :fixtures, :url, :fullpath
  end

  def self.down
    rename_column :fixtures, :fullpath, :url
  end
end
