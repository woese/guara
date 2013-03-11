module Guara
    module Jobs
      module ProcessInstanceHelper
        #include Guara::Jobs::ActiveProcess::ProcessStepComponent
      	def get_collection(vals, sels)
      	    vals = vals.dup
            sels = [] if sels.class == String
            vals.strip!
            if (vals =~ /^\$/) == 0
                vals.gsub!(/^\$/)
                model = eval vals
                if (model.respond_to?(:select_options))
                    options = model.select_options
                else
                    options = model.all
                end
       		    
                options_for_select(options.map { |ff| [ff.name, ff.id] }, (sels || []).collect { |fs| fs[:value] })
            elsif (vals =~ /url:([^\s]*)/)==0
              vals.scan /url:([^\s])/ do |url|
                
              end
            else
                index = -1
                options_for_select(vals.split(',').each { |ff| index+=1; [index, ff] }, sels.collect { |fs| fs[:value] })
            end
    	end

        def get_value_model(vals, id)
            vals.strip!
            if !(vals.nil? && vals.empty?) && vals[0]=='$'
                model = vals[1..1000]
                model = eval model
                
                record = model.find i                                
                return name_or_nothing record.name
                
            else
                id
            end
        end

    	def show_label_tag(label)
            label_tag label, label+":", :class => "strong"
        end

        def show_span_tag(text)
        	content_tag :span, text+":", :class => "strong"
        end

        def get_field(form, rec, val)
        	@field = ""
        	if rec.type_field == 'date'
    		    @field = form.text_field rec.id, :class=> "input-block-level date_format", :value=> val
    		elsif rec.type_field == 'textarea'
    		    @field = form.text_area rec.id, :rows=>"6", :class=> "input-block-level", :value=> val
            elsif rec.type_field == 'select'
                @field = form.select rec.id, get_collection(rec.options, val), {}, :class=> "input-block-level multiselect", :multiple=>"multiple"
            elsif rec.type_field == 'widget'
                if rec.options == 'component'
                    @component = eval(rec.widget).new()
                    params[:process_instance_id] = params[:id]
                    @component.request = request
                    @component.response = response
                    @component.params = params

                    return @component.index
                else
                    return render :partial=> "guara/jobs/widgets/form_#{rec.widget}", :locals=> {:value=> val, :field_form_name=> process_instance_field_form_name(rec)}
                end
            else
                @field = form.text_field rec.id, :value=> val, :class=> "input-block-level #{rec.type_field}"
        	end

        	return "<div class=\"control-group\">
        			<label class=\"control-label strong\" for=\"#{rec.id}\">#{rec.title} #{'<span style="color:red">*</span>' if rec.required == true}</label>
    			        <div class=\"controls\">
    						#{@field}
    					</div>
    				</div>"
        end
        
        def process_instance_field_form_name(step_attr)
          "step_instance_attrs[#{step_attr.id}]"
        end

        def get_fields(form, steps, vals, column)
        	@steps_attrs_column = []
        	if steps[column] != nil
    	    	steps[column].each do |s|
    	    		@steps_attrs_column << get_field(form, s, vals)
    	    	end
        	end
        	return @steps_attrs_column.join("").html_safe
        end
        
        def instance_process_field(form, process_instance, step_attr)
          attr_value = StepInstanceAttr.where(process_instance_id: process_instance.id, step_attr_id: step_attr.id).first
          
          if attr_value.nil?
            value =  process_instance_field_multi_values(step_attr, attr_value)
          else
            value = attr_value.value
          end
          
          raw get_field(form, step_attr, value)
        end

        
        def process_instance_field_multi_values(step_attr, attr_instance)
         return nil if attr_instance.nil?
         
         ret = []
         
          attr_instance.values.each do |v|
            ret << { :value=> v.value, :step_attr_option=> step_attr.options }
          end
          
          return ret
        end

        def process_instance_js_required_fields(step)
            @required_fields = []
            step.attrs.each do |step_attr|
                if step_attr.type_field != 'widget' and step_attr.required == true
                    @required_fields << "if(jQuery.trim($('#step_instance_attrs_#{step_attr.id}').val())== '') {alert('Preencha o campo #{step_attr.title}');return false;};"
                end
            end

            return @required_fields.join("").html_safe
        end

        def show_values_select(val)
            @label = []
            if val.class == Array
                val.each do |k|
                    @label << content_tag(:span, get_value_model(k[:step_attr_option], k[:value]), :class => "strong")
                end
            elsif val.class == String
                @label << val
            end

            return @label.join(", ").html_safe
        end

        def get_value_select(val)
            return get_value_model(val[:step_attr_option], val[:value])
        end

      end
  end
end
