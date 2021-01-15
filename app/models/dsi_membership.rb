class DsiMembership < ApplicationRecord
  belongs_to :organisation
  belongs_to :publisher
end
