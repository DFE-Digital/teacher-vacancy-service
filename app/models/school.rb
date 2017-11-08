class School < ApplicationRecord
  belongs_to :school_type, required: true
  belongs_to :detailed_school_type, optional: true
  belongs_to :region

  enum phase: {
    not_applicable: 0,
    nursery: 1,
    primary: 2,
    middle_deemed_primary: 3,
    secondary: 4,
    middle_deemed_secondary: 5,
    sixteen_plus: 6,
    all_through: 7,
  }
end
