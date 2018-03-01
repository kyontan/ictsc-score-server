class FixTeamPrivateToProblems < ActiveRecord::Migration[5.1]
  def change
    change_column :problems, :team_private, :boolean, default: false, null: false
  end
end
