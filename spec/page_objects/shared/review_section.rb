module PageObjects
  module Shared
    class ReviewSection < SitePrism::Section
      class Row < SitePrism::Section
        element :value, ".govuk-summary-list__value"
      end

      element :heading, ".review-component__heading"

      section :body, ".review-component__body" do
        sections :rows, Row, ".govuk-summary-list__row"

        sections :accordions, ".govuk-accordion__section" do
          section :content, ".govuk-accordion__section-content" do
            sections :rows, Row, ".govuk-summary-list__row"
          end
        end
      end
    end
  end
end
