class ChangeSayWhenFkType < ActiveRecord::Migration
  def change
    reversible do |dir|
      change_table :say_when_jobs do |t|
        dir.up   { t.change :scheduled_id, :string }
        dir.down { t.change :scheduled_id, :integer }
      end
    end
  end
end
