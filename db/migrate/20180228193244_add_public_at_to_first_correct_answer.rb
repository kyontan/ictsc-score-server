class AddPublicAtToFirstCorrectAnswer < ActiveRecord::Migration[5.1]
  def change
    add_column :first_correct_answers, :public_at, :datetime, null: false
  end
end
