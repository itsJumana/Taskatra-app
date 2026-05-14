class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :assignee, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :parent, foreign_key: { to_table: :tasks, on_delete: :cascade }
      t.text :title, null: false
      t.text :description
      t.text :status, null: false, default: "backlog"
      t.integer :priority, null: false, default: 2
      t.integer :position, null: false, default: 0
      t.date :due_date
      t.timestamps
    end
    add_index :tasks, [ :project_id, :status ]
    add_index :tasks, :due_date, where: "due_date IS NOT NULL"
    execute <<~SQL
      CREATE INDEX tasks_fts_idx ON tasks
        USING GIN (to_tsvector('english', title || ' ' || COALESCE(description, '')));
    SQL
  end
end
