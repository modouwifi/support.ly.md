require "lotus/model"

class Ticket
  include Lotus::Entity

  self.attributes = :username, :phone, :email, :order_number, :sn, :mac, :support_type, :additional_info, :source_ip
end
