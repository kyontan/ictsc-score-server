class AddOrderToProblem < ActiveRecord::Migration[5.1]
  def change
    add_column :problems, :order, :integer, default: 0, null: false
  end
end
