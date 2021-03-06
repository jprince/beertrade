class Notification < ActiveRecord::Base
  paginates_per 5

  belongs_to :user
  belongs_to :trade

  validates :user,      presence: true
  validates :message,   presence: true
  validates :trade,     presence: true
  validates :hashcode,  presence: true, uniqueness: true

  scope :unseen,    ->{ where("seen_at IS NULL") }

  before_validation :create_hashcode


  def seen?
    seen_at?
  end


  def mark_as_seen!
    update_attributes(seen_at: Time.now)
  end

  
  def self.updated_shipping(participant)
    participant.other_participants.each do |p|
      if_not_already_sent do
        n = Notification.create!(user: p.user, 
                             message: "#{participant.user} has shipped",
                             trade: p.trade)

        Reddit.pm(p.user.username, "#{participant.user} has shipped", 
                  'notifications/updated_shipping', 
                  participant: participant, notification: n)
      end
    end
  end


  def self.send_invites(participants)
    participants.each do |p|
      if_not_already_sent do
        n = Notification.create!(user: p.user, 
                             message: "you have been invited to a trade",
                             trade: p.trade)

        Reddit.pm(p.user.username, "/r/beertrade trade invite", 
                  'notifications/invite', 
                  participant: p, notification: n)
      end
    end
  end


  def self.left_feedback(participant)
    other_username = participant.other_participant.user.to_s

    if_not_already_sent do
      n = Notification.create!(user: participant.user, 
                           message: "#{other_username} has left you feedback",
                           trade: participant.trade)

      Reddit.pm(participant.user.username, "#{other_username} has left you feedback", 
                "notifications/left_feedback", 
                participant: participant, notification: n)
    end
  end


  private

    def self.if_not_already_sent
      Notification.transaction do
        begin
          yield
        rescue ActiveRecord::RecordInvalid => e
          raise unless e.record.errors.messages.include?(:hashcode)
        end
      end
    end

    def create_hashcode
      return unless user
      self.hashcode = Digest::SHA1.hexdigest(user.id.to_s << message << trade.id.to_s)
    end
end
