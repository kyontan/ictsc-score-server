class ChangeNotUniqueFcaAnswer < ActiveRecord::Migration[5.1]
  def change
    remove_reference :first_correct_answers, :problem
    add_reference :first_correct_answers, :problem, null: false, unique: false
  end
end
