class AddTeamPrivateToProblems < ActiveRecord::Migration[5.1]
  def change
    add_column :problems, :team_private, :boolean, default: true, null: false
  end
end
