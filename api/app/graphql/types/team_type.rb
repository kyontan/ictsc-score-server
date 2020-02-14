# frozen_string_literal: true

module Types
  class TeamType < Types::BaseObject
    field :id,           ID, null: false
    field :role,         Types::Enums::TeamRole, null: false
    field :beginner,     Boolean, null: false
    field :name,         String,  null: true
    field :organization, String,  null: true
    field :number,       Integer, null: true
    field :color,        String,  null: true
    field :secret_text,  String,  null: true
    # channelはgraphqlでは渡さない

    field :attachments,  [Types::AttachmentType], null: false
    field :penalties,    [Types::PenaltyType],    null: false

    has_many :attachments
    has_many :penalties
  end
end
