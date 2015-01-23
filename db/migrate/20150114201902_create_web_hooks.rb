class CreateWebHooks < ActiveRecord::Migration
  def change
    create_table :web_hooks do |t|
      t.uuid     :informer_id
      t.string   :informer_type
      t.string   :url
      t.text     :message
      t.datetime :completed_at
      t.integer  :retry_max, default:  0
      t.integer  :retry_count, default:  0
      t.timestamps null: false
    end

    add_index :web_hooks, [:informer_id, :informer_type], name: 'index_web_hooks_on_informer_id_and_informer_type'
  end
end
