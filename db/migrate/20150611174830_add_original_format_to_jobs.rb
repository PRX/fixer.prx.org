class AddOriginalFormatToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :original_format, :string
  end
end
