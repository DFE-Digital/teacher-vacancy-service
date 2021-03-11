class CreateOrganisationPublishers < ActiveRecord::Migration[6.1]
  def change
    create_table :organisation_publishers, id: :uuid do |t|
      t.uuid :organisation_id
      t.uuid :publisher_id

      t.timestamps
    end
  end
end
