class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs, id: :uuid, default: 'uuid_generate_v4()' do |t|

      t.string  :job_type
      t.text    :original
      t.integer :status
      t.integer :client_application_id
      t.text    :call_back
      t.integer :priority
      t.integer :retry_max, default: 0
      t.integer :retry_count, default: 0
      t.integer :retry_delay, default: 0

      t.timestamps null: false
    end
  end
end
