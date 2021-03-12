require "rails_helper"
RSpec.describe "Creating a vacancy" do
  include ActiveJob::TestHelper

  let(:publisher) { create(:publisher, email: "test@mail.com") }
  let(:school) { create(:school) }

  before do
    ActionMailer::Base.deliveries.clear
    login_publisher(publisher: publisher, organisation: school)
  end

  after { travel_back }

  context "Hiring staff has expired vacancy that is not older than 2 weeks" do
    scenario "does not receive feedback prompt e-mail" do
      vacancy = create(
        :vacancy,
        :published,
        job_title: "Vacancy",
        publish_on: Date.current,
        expires_on: Date.current + 1.week,
        publisher_id: publisher.id,
      )
      vacancy.organisation_vacancies.create(organisation: school)

      travel 2.weeks do
        perform_enqueued_jobs do
          SendExpiredVacancyFeedbackEmailJob.new.perform
        end

        expect(ApplicationMailer.deliveries.count).to eq(0)
      end
    end
  end

  context "Hiring staff has 2 expired vacancies that are older than 2 weeks" do
    scenario "receives feedback prompt email with 2 vacancies" do
      vacancy = create(
        :vacancy,
        :published,
        job_title: "Job one",
        publish_on: Date.current,
        expires_on: Date.current,
        publisher_id: publisher.id,
      )
      vacancy.organisation_vacancies.create(organisation: school)

      vacancy = create(
        :vacancy,
        :published,
        job_title: "Job two",
        publish_on: Date.current,
        expires_on: Date.current,
        publisher_id: publisher.id,
      )
      vacancy.organisation_vacancies.create(organisation: school)

      vacancy = create(
        :vacancy,
        :published,
        job_title: "Job three",
        publish_on: Date.current,
        expires_on: Date.current + 2.weeks,
        publisher_id: publisher.id,
      )
      vacancy.organisation_vacancies.create(organisation: school)

      travel 2.weeks do
        perform_enqueued_jobs do
          SendExpiredVacancyFeedbackEmailJob.new.perform
        end

        expect(ApplicationMailer.deliveries.first.to).to eq(["test@mail.com"])
        expect(ApplicationMailer.deliveries.count).to eq(1)
        expect(ApplicationMailer.deliveries.first.body).to have_content("Job one")
        expect(ApplicationMailer.deliveries.first.body).to have_content("Job two")
        expect(ApplicationMailer.deliveries.first.body).to_not have_content("Job three")
      end
    end
  end

  context "Two expired vacancies for two users that are older than 2 weeks" do
    scenario "both receives feedback prompt emails" do
      another_user = create(:publisher, email: "another@user.com")
      vacancy = create(
        :vacancy,
        :published,
        job_title: "Job one",
        publish_on: Date.current,
        expires_on: Date.current,
        publisher_id: publisher.id,
      )
      vacancy.organisation_vacancies.create(organisation: school)

      vacancy = create(
        :vacancy,
        :published,
        job_title: "Job two",
        publish_on: Date.current,
        expires_on: Date.current,
        publisher_id: another_user.id,
      )
      vacancy.organisation_vacancies.create(organisation: school)

      travel 2.weeks do
        perform_enqueued_jobs do
          SendExpiredVacancyFeedbackEmailJob.new.perform
        end

        expect(ApplicationMailer.deliveries.map(&:to)).to match a_collection_containing_exactly(
          ["another@user.com"], ["test@mail.com"]
        )
        expect(ApplicationMailer.deliveries.count).to eq(2)
      end
    end
  end
end
