# frozen_string_literal: true

class CreateImports < ActiveRecord::Migration[8.1]
  def change
    create_table :imports do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0, index: true
      t.integer :total_rows, null: false, default: 0
      t.integer :succeeded_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.string :failure_reason
      t.json :row_errors, null: false, default: []
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps

      t.check_constraint "status BETWEEN 0 AND 4", name: "imports_status_check"
      t.check_constraint "total_rows >= 0", name: "imports_total_rows_check"
      t.check_constraint "succeeded_rows >= 0", name: "imports_succeeded_rows_check"
      t.check_constraint "failed_rows >= 0", name: "imports_failed_rows_check"
    end
  end
end
