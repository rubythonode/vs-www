class Photo < ActiveRecord::Base
  attr_protected
  has_one :issue
  has_one :stock
  has_one :user
  attr_accessor :image, :image_url
  has_attached_file :image, :styles => { :xlarge => "180x180#", :large => "130x130#", :medium => "768x200#", :small => "45x45#" },
    :url => "/images/photos/:id/:id_:style.:extension"
  before_validation :download_remote_image, :if => :image_url_provided?
  def medium 
    sprintf("%s",image.url(:medium))
  end
  
  def large
    sprintf("%s",image.url(:large))
  end

  def xlarge
    sprintf("%s",image.url(:xlarge))
  end

  def original 
    sprintf("%s",image.url(:original))
  end
  
  def image_url_provided?
    !self.image_url.blank? 
  end

  def download_remote_image
    self.image = do_download_remote_image
    #self.image_remote_url = image_url
  end

  def do_download_remote_image
    io = open(URI.parse(image_url))
    def io.original_filename; base_uri.path.split('/').last; end
    io.original_filename.blank? ? nil : io
  rescue # catch url errors with validations instead of exceptions (Errno::ENOENT, OpenURI::HTTPError, etc...)
  end
end
