require "rails_helper"

RSpec.describe Organisation, type: :model do
  it { is_expected.to have_many(:publishers) }
  it { is_expected.to have_many(:organisation_publishers) }
  it { is_expected.to have_many(:vacancies) }
  it { is_expected.to have_many(:organisation_vacancies) }
end
