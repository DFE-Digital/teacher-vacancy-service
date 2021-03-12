require "rails_helper"
RSpec.describe Authorisation do
  describe ".new" do
    it "requires an organisation_id and user_id" do
      result = described_class.new(
        organisation_id: "123", user_id: "456",
      )

      expect(result).to be_kind_of(described_class)
    end
  end

  describe "#call" do
    let(:stubbed_time) { Time.zone.local(2019, 9, 1, 12, 0, 0) }
    subject do
      described_class.new(
        organisation_id: "939eac36-0777-48c2-9c2c-b87c948a9ee0",
        user_id: "161d1f6a-44f1-4a1a-940d-d1088c439da7",
      )
    end

    before do
      stub_authorisation_step
      travel_to stubbed_time
    end

    after { travel_back }

    it "stores the role_ids" do
      result = subject.call
      expect(result.role_ids).to eq(%w[test-role-id])
    end

    it "configure SSL to be used for this request" do
      expect(Net::HTTP).to receive(:start)
        .with(anything, anything, use_ssl: true)
        .and_return(double(code: "200", body: '{ "roles": [] }'))

      subject.call
    end

    it "sets the request headers for authorisation and content" do
      jwt_token = double
      expect(JWT).to receive(:encode).with(
        {
          iss: "schooljobs",
          exp: (stubbed_time + 60).to_i,
          aud: "signin.education.gov.uk",
        },
        "test-password",
        "HS256",
      ).and_return(jwt_token)

      request_double = double(Net::HTTP::Get)
      expect(Net::HTTP::Get).to receive(:new).and_return(request_double)
      expect(request_double).to receive(:[]=).with("Content-Type", "application/json")
      expect(request_double).to receive(:[]=).with("Authorization", "bearer #{jwt_token}")

      expect_any_instance_of(Net::HTTP).to receive(:request)
        .with(request_double)
        .and_return(double(code: "200", body: '{ "roles": [] }'))

      subject.call
    end

    context "when the response is a 404" do
      it "continues to return the authorisation object with no role_ids" do
        stub_authorisation_step_with_not_found

        result = subject.call

        expect(result).to be_kind_of(Authorisation)
        expect(result.role_ids).to be nil
      end
    end

    context "when the external response status is 500" do
      before { stub_authorisation_step_with_external_error }

      it "raises an external server error" do
        expect { subject.call }.to raise_error(Authorisation::ExternalServerError)
      end
    end
  end

  describe "#authorised?" do
    subject do
      described_class.new(
        organisation_id: "123",
        user_id: "456",
      )
    end

    context "when roles include a known role_id" do
      it "returns true" do
        subject.role_ids = %w[test-role-id]
        expect(subject.authorised?).to be true
      end
    end

    context "when roles do not include a known role_id" do
      it "returns true" do
        subject.role_ids = %w[unknown-role-id]
        expect(subject.authorised?).to be false
      end
    end

    context "when there are no roles" do
      it "returns false" do
        subject.role_ids = []
        expect(subject.authorised?).to be false
      end
    end
  end

  describe "#many_organisations?" do
    subject do
      described_class.new(
        organisation_id: "939eac36-0777-48c2-9c2c-b87c948a9ee0",
        user_id: user_id,
      )
    end
    let(:user_id) { "default_id" }

    context "user is a member of multiple organisations" do
      let(:user_id) { "161d1f6a-44f1-4a1a-940d-d1088c439da7" }
      it "has many" do
        stub_sign_in_with_multiple_organisations(user_id: user_id)
        expect(subject.many_organisations?).to be(true)
      end
    end

    context "another user is a member of multiple organisations" do
      let(:user_id) { "another_user_id" }
      it "has many" do
        stub_sign_in_with_multiple_organisations(user_id: user_id)
        expect(subject.many_organisations?).to be(true)
      end
    end

    context "user is member of a single organisation" do
      let(:user_id) { "another_user_id" }
      it "does not have many" do
        stub_sign_in_with_single_organisation(user_id: user_id)
        expect(subject.many_organisations?).to be(false)
      end
    end

    context "DfE sign-in has an internal server error" do
      let(:user_id) { "another_user_id" }
      it "is nil" do
        stub_request(
          :get,
          "https://test-url.local/users/#{user_id}/organisations",
        ).to_return(status: 500)
        expect(subject.many_organisations?).to be(nil)
      end
    end
  end
end
