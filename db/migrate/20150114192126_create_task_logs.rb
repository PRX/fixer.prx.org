class CreateTaskLogs < ActiveRecord::Migration
  def change
    create_table :task_logs do |t|
      t.uuid      :task_id
      t.integer   :status
      t.string    :message
      t.text      :info
      t.datetime  :logged_at
      t.timestamps null: false
    end

    add_index :task_logs, [:task_id], name: 'index_task_logs_on_task_id'
  end
end
