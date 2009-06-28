class Slide < ActiveRecord::Base
  has_attached_file :image,
                    :styles => { :large => '640x480>' }
end
