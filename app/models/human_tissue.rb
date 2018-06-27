class HumanTissue < ActiveRecord::Base
  has_many :human_stats
  has_many :human_datas
end


# == Schema Information
#
# Table name: assays
#
#  id          :integer(4)      not null, primary key
#  slug        :string(255)
#  name        :string(255)
#  description :string(255)
#
