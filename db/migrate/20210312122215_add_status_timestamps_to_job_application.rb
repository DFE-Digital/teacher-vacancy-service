class AddStatusTimestampsToJobApplication < ActiveRecord::Migration[6.1]
  def change
    add_column :job_applications, :draft_at, :datetime
    add_column :job_applications, :shortlisted_at, :datetime
    add_column :job_applications, :unsuccessful_at, :datetime
    add_column :job_applications, :withdrawn_at, :datetime
  end
end
