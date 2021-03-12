require "page_objects/shared/review_section"

module PageObjects
  module Jobseekers
    module JobApplications
      class Review < SitePrism::Page
        set_url "jobseekers/job_applications{/job_application_id}/review"

        sections :steps, PageObjects::Shared::ReviewSection, ".review-component"
      end
    end
  end
end
