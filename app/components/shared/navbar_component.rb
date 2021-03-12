class Shared::NavbarComponent < ViewComponent::Base
  delegate :active_link_class, to: :helpers
  delegate :current_organisation, to: :helpers
  delegate :organisation_type_basic, to: :helpers
  delegate :jobseeker_signed_in?, to: :helpers
  delegate :publisher_signed_in?, to: :helpers
end
