
module Guara
  module Jobs
    class ProcessInstanceController < Guara::BaseController
      load_and_authorize_resource :process_instance, :class => "Guara::Jobs::ProcessInstance"
      load_and_authorize_resource :custom_process, :class => "Guara::Jobs::CustomProcess"

      helper CrudHelper

      attr_accessor :embedded

      def index
        params[:search] = {:finished_is_false=> true} if params[:search].nil?
        params[:search][:process_id_eq] = Vacancy.custom_process.id
        params[:search][:finished_is_false] = true if params[:search][:finished_is_true] == '0'

        @search = ProcessInstance.search(params[:search])
        if class_exists?("Ransack")
            @process_instance = @search.result().paginate(page: params[:page], :per_page => 10)
        else
            @process_instance = @search.paginate(page: params[:page], :per_page => 10)
        end
      end

      def new
        @custom_process = Vacancy.custom_process
        @process_instance = ProcessInstance.new
        
        @process_instance.update_attributes({
          :process_id=> @custom_process.id,
          :date_start=> Time.now.to_s(:db),
          :finished=> false,
          :user_using_process=> current_user.id,
          :state=> @custom_process.step_init
        })

        if @process_instance.save
          redirect_to edit_process_instance_path(@process_instance)
        else
          render :index
        end
      end

      def alter_state_process_instance
        @process_instance = ProcessInstance.find params[:id]
        @process_instance.update_attributes :state=> params[:state]
        @process_instance.save

        redirect_to edit_process_instance_path(params[:id])
      end

      def edit
        @process_instance = ProcessInstance.find params[:id]
        
        if params[:edit_step].nil?
          @current_step = @process_instance.step
          params[:edit_step] = @current_step.id
        else
          @current_step = Step.find params[:edit_step]
        end
        
        @grouped_column_attrs_current_step = load_grouped_columned_attrs(@current_step)
        @grouped_column_attrs_step_init    = load_grouped_columned_attrs(@process_instance.custom_process.step)

        if @embedded
          render :partial => "guara/jobs/process_instance/form"
        else

        end
      end
      
      def load_grouped_columned_attrs(step)
        grouped_attrs = step.attrs.group_by(&:group).sort()
        
        grouped_column_attrs = {}
        
        grouped_attrs.each do |group, attrs|
          grouped_column_attrs[group] = attrs.group_by(&:column)
        end
        
        if grouped_column_attrs.include? ''
          grouped_column_attrs[:default] = grouped_column_attrs['']
          grouped_column_attrs.delete('')
        end
        return grouped_column_attrs
      end

      def create_step_instance_attrs
        @step_instance_attrs.each do |key, value|
          step_attr_val = {
            :process_instance_id=> params[:id], 
            :step_attr_id=> key, 
            :step_id=>@step_id, 
            :value=> nil
          }

          if value.class == Array
            @step_instance_attr = StepInstanceAttr.create(step_attr_val)
            value.each do |attr|
              @step_instance_attr.step_instance_attr_multis.create :value=> attr
            end
          else
            step_attr_val[:value] = value
            @step_instance_attr = StepInstanceAttr.create(step_attr_val)
          end
        end
      end

      def update
        @step_instance_attrs = params[:step_instance_attrs]
        @step_id = @step_instance_attrs.delete(:step_id)

        StepInstanceAttr.delete_all("step_id = #{@step_id} AND process_instance_id = #{params[:id]}")

        create_step_instance_attrs()
        set_next_step_to_process_instance()

        if !@embedded
          redirect_to process_instance_show_step_path(:id=> params[:id], :edit_step=> @step_id)
        end  
      end

      def load_next_step_to_process_instance
        @process_instance = ProcessInstance.find params[:id]
        @next_step = @process_instance.step.next
        step_attr_count = StepAttr.where(:step_id=> @next_step).count()
        if step_attr_count == 0 || @process_instance.state != @next_step
          @next_step_valid = 0
        else
          @next_step_valid = 1
        end
      end

      def set_next_step_to_process_instance
        load_next_step_to_process_instance()

        if @next_step.nil? or @next_step_valid == 0
          #@process_instance.update_attributes :date_finish=> Time.now.to_s(:db)
          #@process_instance.save
        else
          @process_instance.update_attributes :state=> @next_step
          @process_instance.save
        end 
      end

      def finish_process_instance
        @process_instance = ProcessInstance.find params[:process_instance_id]
        @process_instance.update_attributes :date_finish=> Time.now.to_s(:db), :finished=> true
        @process_instance.save

        redirect_to process_instance_index_path
      end

      def show_step
        edit
      end
      
      def show
        @process_instance = ProcessInstance.find params[:id]
        @grouped_column_attrs_step_init = load_grouped_columned_attrs(@process_instance.custom_process.step)
        @grouped_column_attrs_current_step = load_grouped_columned_attrs(@process_instance.step)
        @step_order = @process_instance.steps_previous_current

        if @embedded
          render :partial => "guara/jobs/process_instance/details_current_stage"
        else
          render
        end
      end
      
      def embeded_call(action, process_instance, params, request, response)
        params = params.dup
        params[:id] = process_instance.id
        params[:action] = action
        params[:process_instance] = nil
        params[:edit_step] = nil

        self.params = params
        self.request = request
        self.response = response

        self.embedded = true

        return self.send(action)
      end
    end
  end
end

