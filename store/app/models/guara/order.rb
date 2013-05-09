module Guara
  class Order < ActiveRecord::Base
    
    attr_accessible :person, :date_finish, :date_init, :payment_date, :payment_state, :items,
                    :payment_type, :payment_parts, :person_id, :state, :state_date, :type, :products,
                    :items_attributes
    
    belongs_to :person
    

    has_many :items, class_name: "Guara::OrderItem"
    has_many :products, through: :items

    accepts_nested_attributes_for :items, :reject_if => proc { |att| (att['_destroy'] == '1') },
    :allow_destroy => true

    public
      def state=(state)
        write_attribute :state, state
        self.state_date = Time.now
      end
  
      def self.total_in_on(date)
        where(date_init: date).joins(:items).sum("price*total")
      end
  
      def self.total_out_on(date)
        where(date_init: date).joins(:items).sum("price*total")
      end
      
  end
end
