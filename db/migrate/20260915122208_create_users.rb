# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :full_name, null: false
      t.string :email, null: false, index: {unique: true}
      t.string :password_digest, null: false
      t.integer :role, null: false, default: 0, index: true

      t.timestamps

      t.check_constraint "role IN (0, 1)", name: "users_role_check"
    end
  end
end
