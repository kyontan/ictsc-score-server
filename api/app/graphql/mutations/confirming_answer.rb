# frozen_string_literal: true

module Mutations
  class ConfirmingAnswer < BaseMutation
    field :answer, Types::AnswerType, null: true

    argument :answer_id, ID, required: true
    argument :confirming, Boolean, required: true

    def resolve(answer_id:, confirming:)
      Acl.permit!(mutation: self, args: {})

      answer = Answer.find_by(id: answer_id)
      raise RecordNotExists.new(Answer, id: answer_id) if answer.nil?

      if answer.update(confirming: confirming)
        { answer: answer.readable }
      else
        add_errors(answer)
      end
    end
  end
end
