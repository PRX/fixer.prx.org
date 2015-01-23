class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks, id: :uuid, default: 'uuid_generate_v4()' do |t|
      t.uuid     :job_id
      t.string   :task_type
      t.string   :label
      t.text     :options
      t.text     :call_back
      t.text     :result
      t.integer  :status
      t.integer  :sequence_id
      t.integer  :position
      t.string   :type

      t.timestamps null: false
    end

    add_index :tasks, [:job_id], name: 'index_tasks_on_job_id'
    add_index :tasks, [:position, :sequence_id], name: 'index_tasks_on_position_and_sequence_id'
    add_index :tasks, [:sequence_id], name: 'index_tasks_on_sequence_id'
  end
end

