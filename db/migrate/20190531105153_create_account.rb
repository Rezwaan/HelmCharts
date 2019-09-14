class CreateAccount < ActiveRecord::Migration[5.2]
  def change
    create_table :accounts, id: :uuid do |t|
      t.string :name, null: false, default: ""
      t.string :username, null: false, default: ""
      t.string :password_digest, null: false, default: ""
      t.timestamps null: false
    end
    add_index :accounts, :username, unique: true
  end
end
