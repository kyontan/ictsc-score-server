class AddSolvedToScore < ActiveRecord::Migration[5.1]
  def change
    add_column :scores, :solved, :boolean, default: false, null: false
  end
end
