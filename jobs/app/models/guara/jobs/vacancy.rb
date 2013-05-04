module Guara
  module Jobs
    class Vacancy < ActiveRecord::Base
      attr_accessible :process_instance, :process_instance_id, :status, :status_id, :system_name,
                      :customer_id, :role_id, :type_id, :total, :salary_id, :consultante_id
      belongs_to :process_instance
      
      after_save :after_save_check_status

      @user_changed = nil

      has_many :histories, class_name: "Guara::Jobs::VacancyStatusHistory"

      def selection_professionals_selecteds()
        @step_profs = self.process_instance.custom_process.steps.joins(:step_attrs).where("guara_jobs_step_attrs.widget='selecionar_candidatos'").first
        raise "Unkow step with professionals selection" if @step_profs.nil?
        @step_attr = @step_profs.attrs.where("guara_jobs_step_attrs.widget='selecionar_candidatos'").first
        
        @attr_inst = StepInstanceAttr.where(process_instance_id: self.process_instance.id, step_attr_id: @step_attr.id).first
        raise "Unkow attrs with professionals selection" if @attr_inst.nil?
        @attr_inst.values.map { |v| Professional.find v.value }
      end
      
      def self.custom_process
        CustomProcess.where(name: 'vacancy').order(:created_at).last
      end
      
      def status
        VacancyStatus.enum[self.status_id]
      end
      
      def change_status(new_status)
        if status.routes.include?(new_status)

          self.status_id = new_status.id
        else
          raise "Status invalid. Status %s not in router %s" % [new_status.name, status.routes.map(&:name).join(", ")]
        end
      end

      def change_status!(new_status, user=nil)
        self.change_status(new_status)
        @user_changed = user
        self.save!
      end
        
      def self.custom_process_id
        cp = self.custom_process
        unless cp.nil?
          cp.id
        else
          -1
        end
        
      end

      private
        def after_save_check_status
          if status_id_changed?

            histories.create(
                :user => @user_changed,
                status_old: self.status_id_was,
                status_new: self.status_id
              )
          end
        end
    end
  end
end
