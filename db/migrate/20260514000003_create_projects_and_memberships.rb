class CreateProjectsAndMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :projects do |t|
      t.text :name, null: false
      t.text :slug, null: false
      t.text :description
      t.text :status, null: false, default: "active"
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :projects, :slug, unique: true

    create_table :project_memberships do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.text :role, null: false, default: "member"
      t.timestamps
    end
    add_index :project_memberships, [ :project_id, :user_id ], unique: true
  end
end
