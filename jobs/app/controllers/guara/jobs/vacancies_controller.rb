
module Guara
  module Jobs
    class VacanciesController < BaseController

      def change_status
        @vacancy = Vacancy.find params[:vacancy_id]
        authorize! :read, @vacancy
        status_to_change = VacancyStatus.enum[params[:status_id]]
        @vacancy.change_status status_to_change
        redirect_to process_instance_path(@vacancy.process_instance)
      end
      
    end
  end
end