class HumanData < ActiveRecord::Base

  belongs_to :HumanTissue
  belongs_to :probeset
  has_one :human_stat

end


# == Schema Information
#
# Table name: probeset_datas
#
#  id             :integer(4)      not null, primary key
#  assay_id       :integer(4)
#  assay_name     :string(255)
#  probeset_name  :string(255)
#  time_points    :string(1000)
#  data_points    :string(1000)
#
