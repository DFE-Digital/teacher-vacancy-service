JOB_APPLICATION_DATA = {
  # Personal details
  first_name: Faker::Name.first_name,
  last_name: Faker::Name.last_name,
  previous_names: Faker::Name.name,
  building_and_street: Faker::Address.street_address,
  town_or_city: Faker::Address.city,
  postcode: Faker::Address.postcode,
  phone_number: "01234 567890",
  teacher_reference_number: "12345678",
  national_insurance_number: "QQ 12 34 56 C",
  # Professional status
  qualified_teacher_status: "yes",
  qualified_teacher_status_year: "1990",
  statutory_induction_complete: "yes",
  # Personal statement
  personal_statement: Faker::Lorem.paragraph(sentence_count: 8),
  # Equal opportunities
  disability: "no",
  gender: "other",
  gender_description: Faker::Lorem.sentence,
  orientation: "other",
  orientation_description: Faker::Lorem.sentence,
  ethnicity: "other",
  ethnicity_description: Faker::Lorem.sentence,
  religion: "other",
  religion_description: Faker::Lorem.sentence,
  # Ask for support
  support_needed: "yes",
  support_details: Faker::Lorem.paragraph(sentence_count: 2),
  # Declarations
  banned_or_disqualified: "no",
  close_relationships: "yes",
  close_relationships_details: Faker::Lorem.paragraph(sentence_count: 1),
  right_to_work_in_uk: "yes",

  # From publisher
  further_instructions: Faker::Lorem.paragraph(sentence_count: 2),
  rejection_reasons: Faker::Lorem.paragraph(sentence_count: 1),
}.freeze

FactoryBot.define do
  factory :job_application do
    transient do
      draft_at { 2.weeks.ago }
      shortlisted_at { 2.days.ago }
      submitted_at { 3.days.ago }
      unsuccessful_at { 1.day.ago }
      withdrawn_at { 1.week.ago }
    end

    status { :draft }
    jobseeker
    vacancy

    application_data { JOB_APPLICATION_DATA }
    completed_steps { JobApplication.completed_steps.keys }

    after :create do |job_application, options|
      unless job_application.draft?
        # TODO: education
        create_list :job_application_detail, 3, :employment_history, job_application: job_application
        create_list :job_application_detail, 2, :reference, job_application: job_application
      end

      job_application.update_columns(
        draft_at: options.draft_at,
        shortlisted_at: options.shortlisted_at,
        submitted_at: options.submitted_at,
        unsuccessful_at: options.unsuccessful_at,
        withdrawn_at: options.withdrawn_at,
      )
    end
  end

  trait :status_draft do
    status { :draft }
    application_data { {} }
    completed_steps { [] }
  end

  trait :status_shortlisted do
    status { :shortlisted }
  end

  trait :status_submitted do
    status { :submitted }
  end

  trait :status_unsuccessful do
    status { :unsuccessful }
  end

  trait :status_withdrawn do
    status { :withdrawn }
  end
end
