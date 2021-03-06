require "rails_helper"

RSpec.describe UpdateDsiUsersInDb do
  let(:test_file_1_path) { Rails.root.join("spec/fixtures/dfe_sign_in_service_users_response_page_1.json") }
  let(:test_file_2_path) { Rails.root.join("spec/fixtures/dfe_sign_in_service_users_response_page_2.json") }
  let(:test_file_empty_users_path) { Rails.root.join("spec/fixtures/dfe_sign_in_service_users_empty_response.json") }
  let(:update_dfe_sign_in_users) { described_class.new }

  describe "#run!" do
    before do
      allow(described_class).to receive(:new).and_return(update_dfe_sign_in_users)
    end

    it "updates the users database with correct emails and URNs/UIDs" do
      allow(update_dfe_sign_in_users).to receive(:number_of_pages).and_return(2)

      [test_file_1_path, test_file_2_path].each_with_index do |file_path, index|
        stub_request(:get, "#{DFE_SIGN_IN_URL}/users?page=#{index + 1}&pageSize=#{DFESignIn::API::USERS_PAGE_SIZE}")
          .to_return(
            body: File.read(file_path),
          )
      end

      expect { update_dfe_sign_in_users.run! }.to change { Publisher.all.size }.by(3)

      user_with_one_school = Publisher.find_by(email: "foo@example.com")
      expect(user_with_one_school.dsi_data["school_urns"]).to eq(%w[111111])
      expect(user_with_one_school.dsi_data["trust_uids"]).to eq([])
      expect(user_with_one_school.dsi_data["la_codes"]).to eq([])
      expect(user_with_one_school.given_name).to eq("Roger")
      expect(user_with_one_school.family_name).to eq("Johnson")

      user_with_multiple_orgs = Publisher.find_by(email: "bar@example.com")
      expect(user_with_multiple_orgs.dsi_data["school_urns"]).to eq(%w[333333 555555])
      expect(user_with_multiple_orgs.dsi_data["trust_uids"]).to eq(%w[222222 444444])
      expect(user_with_one_school.dsi_data["la_codes"]).to eq([])
      expect(user_with_multiple_orgs.given_name).to eq("Alice")
      expect(user_with_multiple_orgs.family_name).to eq("Robertson")

      local_authority_user = Publisher.find_by(email: "baz@example.com")
      expect(local_authority_user.dsi_data["school_urns"]).to eq([])
      expect(local_authority_user.dsi_data["trust_uids"]).to eq([])
      expect(local_authority_user.dsi_data["la_codes"]).to eq(%w[813])
      expect(local_authority_user.given_name).to eq("Barry")
      expect(local_authority_user.family_name).to eq("Scott")
    end

    it "raises an error when it finds no users in the response" do
      allow(update_dfe_sign_in_users).to receive(:number_of_pages).and_return(1)

      stub_request(:get, "#{DFE_SIGN_IN_URL}/users?page=1&pageSize=#{DFESignIn::API::USERS_PAGE_SIZE}")
          .to_return(
            body: File.read(test_file_empty_users_path),
          )
      expect { update_dfe_sign_in_users.run! }.to raise_error("failed request")

      stub_request(:get, "#{DFE_SIGN_IN_URL}/users?page=1&pageSize=#{DFESignIn::API::USERS_PAGE_SIZE}")
          .to_return(
            body: "{}",
          )
      expect { update_dfe_sign_in_users.run! }.to raise_error("failed request")
    end
  end
end
