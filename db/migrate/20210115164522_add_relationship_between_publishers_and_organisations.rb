class AddRelationshipBetweenPublishersAndOrganisations < ActiveRecord::Migration[6.1]
  def change
    create_table :dsi_memberships, id: :uuid do |t|
      t.references :organisation, null: false, foreign_key: true, type: :uuid
      t.references :publisher, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :organisations, :local_authority_code
  end
end
