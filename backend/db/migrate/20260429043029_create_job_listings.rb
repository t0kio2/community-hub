class CreateJobListings < ActiveRecord::Migration[8.1]
  def change
    create_table :job_listings do |t|
      t.references :listing, null: false, foreign_key: true, index: { unique: true }
      t.string :employment_type
      t.string :job_category
      t.string :work_area
      t.string :work_address
      t.string :salary_type
      t.integer :salary_min
      t.integer :salary_max
      t.string :working_hours
      t.string :work_days
      t.text :required_skills
      t.text :welcome_skills
      t.text :benefits
      t.integer :application_limit

      t.timestamps
    end
  end
end
