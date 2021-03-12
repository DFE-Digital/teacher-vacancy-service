# Documentation: app/mailers/previewing_emails.md
class Jobseekers::JobApplicationPreview < ActionMailer::Preview
  def application_shortlisted
    Jobseekers::JobApplicationMailer.application_shortlisted(JobApplication.find("6683c564-15e6-41af-ab44-7adf125f4c84"))
  end

  def application_submitted_at_central_office
    application_submitted("7bfadb84-cf30-4121-88bd-a9f958440cc9")
  end

  def application_submitted_at_multiple_schools
    application_submitted("9910d184-5686-4ffc-9322-69aa150c19d3")
  end

  def application_submitted_at_one_school
    vacancy = School.first.vacancies.where(job_location: "at_one_school").sample
    application_submitted(vacancy.id)
  end

  def application_unsuccessful
    Jobseekers::JobApplicationMailer.application_unsuccessful(JobApplication.find("6683c564-15e6-41af-ab44-7adf125f4c84"))
  end

  private

  def application_submitted(vacancy_id)
    seeded_vacancy = Vacancy.find(vacancy_id)
    job_application = JobApplication.find_by(jobseeker_id: Jobseeker.first.id, vacancy_id: seeded_vacancy.id) ||
                      FactoryBot.create(:job_application, :status_submitted, jobseeker: Jobseeker.first, vacancy: seeded_vacancy)
    Jobseekers::JobApplicationMailer.application_submitted(job_application)
  end
end
