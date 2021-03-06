
module Guara
	module Jobs
		class Professional < ActiveRecord::Base
			include Guara::Core::Engine.routes.url_helpers

			#==================================> ATTRIBUTES <============================#
			attr_accessible :have_job, :business_action, :salary_requirements, 
							:vacancy_specifications, :vacancy_specification_attributes,
							:formations_attributes,  :professional_languages_attributes,
							:professional_experiences_attributes, 
							:attachment, :attachment_attributes,
							:resume_professional, :resume_professional_attributes, :person

			delegate :name, to: :person


			#==============================> ASSOCIATE <============================#
	    	belongs_to :person
	    	belongs_to :customer, foreign_key: "person_id"

			has_one :attachment, dependent: :destroy   
	  		has_many :formations, dependent: :destroy
	  		has_many :professional_experiences, dependent: :destroy
	  		has_one :vacancy_specification, dependent: :destroy
	  		has_many :professional_languages


	  		accepts_nested_attributes_for :attachment

	  		accepts_nested_attributes_for :formations, :allow_destroy => true

	  		accepts_nested_attributes_for :professional_experiences, :allow_destroy => true
	  		 
	  		accepts_nested_attributes_for :vacancy_specification

	  		accepts_nested_attributes_for :professional_languages, :reject_if => lambda { |a| a[:language_id].blank? }, :allow_destroy => true








	  		def base_uri
			    self.new_record? ? new_jobs_customer_professional_path(self.customer, self) : jobs_customer_professional_path(self.customer, self)
			end

		end
	end
end  	

require File.expand_path("../../../../../config/crm_config.rb", __FILE__) if Rails.env.development?
