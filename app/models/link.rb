class Link < ApplicationRecord
  belongs_to :source, class_name: "Page"
  belongs_to :destination, class_name: "Page"
end
