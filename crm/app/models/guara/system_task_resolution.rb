module Guara
  class SystemTaskResolution < ActiveRecord::Base
    attr_accessible :name, :parent, :parent_id
  
    belongs_to :parent, class_name: "SystemTaskResolution"
  
    def self.RESOLVED
      readonly.find_by_name("RESOLVED")
    end
  
    def self.CANCELED
      readonly.find_by_name("CANCELED")
    end
  
    def self.BLOCKED
      readonly.find_by_name("BLOCKED")
    end  
  
    def self.RESOLVED_WITH_BUSINESS
      res = readonly.find_by_name("RESOLVED_WITH_BUSINESS")
    end
    
    def task_status_change
      if (read_attribute(:name)=="BLOCKED")
        Guara::SystemTaskStatus.IN_PROGRESS
      else
        Guara::SystemTaskStatus.CLOSED
      end
    end
  
    def name
      I18n.t("task_resolutions.%s" % super)
    end
  end
end