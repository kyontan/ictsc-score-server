class AddAnswerToFirstCorrectAnswer < ActiveRecord::Migration[5.1]
  def change
    add_reference :first_correct_answers, :answer, null: false
  end
end
